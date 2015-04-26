(*
 * Copyright (c) 2015 Stanislav Artemkin <artemkin@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
*)

open Core.Std
open Async.Std
open Cohttp
open Cohttp_async

let is_sha256_hex_digest str =
  if String.length str <> 64 then false
  else String.for_all str ~f:Char.is_alphanum

module Json = struct
  let error msg =
    let msg = `Assoc [ "message", `String msg ] in
    Yojson.pretty_to_string msg

  let metadata ~oid ~size ~self_url ~download_url =
    let msg = `Assoc [
        "oid", `String oid;
        "size", `Intlit (Int64.to_string size);
        "_links", `Assoc [
          "self", `Assoc [ "href", `String (Uri.to_string self_url) ];
          "download", `Assoc [ "href", `String (Uri.to_string download_url) ]
        ]
      ] in
    Yojson.pretty_to_string msg

  let download url =
    let msg = `Assoc [
        "_links", `Assoc [
          "download", `Assoc [ "href", `String (Uri.to_string url) ]
        ]
      ] in
    Yojson.pretty_to_string msg

  let upload url =
    let url = Uri.to_string url in
    let msg = `Assoc [
        "_links", `Assoc [
          "upload", `Assoc [ "href", `String url ];
          "verify", `Assoc [ "href", `String url ]
        ]
      ] in
    Yojson.pretty_to_string msg

  let parse_oid_size str =
    try_with ~run:`Now (fun () -> return @@ Yojson.Safe.from_string str)
    >>| function
    | Error _ -> None
    | Ok (`Assoc ["oid", `String oid; "size", `Int size]) ->
      if is_sha256_hex_digest oid then
        Some (oid, Int64.of_int size)
      else None
    | Ok (`Assoc ["oid", `String oid; "size", `Intlit size]) ->
      let oid = if is_sha256_hex_digest oid then Some oid else None in
      let size = Option.try_with (fun () -> Int64.of_string size) in
      Option.both oid size
    | Ok _ -> None
end

let add_content_type headers content_type =
  Header.add headers "content-type" content_type

let respond ~headers ~body ~code =
  Server.respond ~headers ~body code >>| fun resp ->
  resp, `Log_ok code

let respond_ok ~code =
  Server.respond code >>| fun resp ->
  resp, `Log_ok code

let respond_error ~code =
  Server.respond code >>| fun resp ->
  resp, `Log_error (code, "")

let prepare_string_respond ~meth ~code msg =
  let headers = add_content_type (Header.init ()) "application/vnd.git-lfs+json" in
  let body = match meth with `HEAD -> `Empty | _ -> `String msg in
  Server.respond ~headers ~body code

let respond_with_string ~meth ~code msg =
  prepare_string_respond ~meth ~code msg >>| fun resp ->
  resp, `Log_ok code

let respond_error_with_message ~meth ~code msg =
  prepare_string_respond ~meth ~code @@ Json.error msg >>| fun resp ->
  resp, `Log_error (code, msg)

let mkdir_if_needed dirname =
  try_with ~run:`Now (fun () -> Unix.stat dirname) >>= function
  | Ok _ -> Deferred.unit
  | Error _ ->
    try_with ~run:`Now (fun () -> Unix.mkdir dirname)
    >>= fun _ -> Deferred.unit

let get_oid_prefixes ~oid =
  (String.prefix oid 2, String.sub oid ~pos:2 ~len:2)

let make_objects_dir_if_needed ~root ~oid =
  let (oid02, oid24) = get_oid_prefixes ~oid in
  let dir02 = Filename.of_parts [root; "/objects"; oid02] in
  let dir24 = Filename.concat dir02 oid24 in
  mkdir_if_needed dir02 >>= fun () ->
  mkdir_if_needed dir24

let get_object_filename ~root ~oid =
  let (oid02, oid24) = get_oid_prefixes ~oid in
  let oid_path = Filename.of_parts [oid02; oid24; oid] in
  Filename.of_parts [root; "/objects"; oid_path]

let get_temp_filename ~root ~oid =
  Filename.of_parts [root; "/temp"; oid]

let check_object_file_stat ~root ~oid =
  let filename = get_object_filename ~root ~oid in
  try_with ~run:`Now (fun () -> Unix.stat filename)

let get_download_url uri oid =
  Uri.with_path uri @@ Filename.concat "/data/objects" oid

let respond_object_metadata ~root ~meth ~uri ~oid =
  check_object_file_stat ~root ~oid >>= function
  | Error _ -> respond_error_with_message ~meth ~code:`Not_found "Object not found"
  | Ok stat ->
    let download_url = get_download_url uri oid in
    respond_with_string ~meth ~code:`OK
    @@ Json.metadata ~oid ~size:(Unix.Stats.size stat) ~self_url:uri ~download_url

let respond_object ~root ~meth ~oid =
  let filename = get_object_filename ~root ~oid in
  try_with ~run:`Now
    (fun () ->
       Reader.open_file filename
       >>= fun rd ->
       let headers = add_content_type (Header.init ()) "application/octet-stream" in
       match meth with
       | `GET ->
         respond ~headers ~body:(`Pipe (Reader.pipe rd)) ~code:`OK
       | `HEAD ->
         Reader.close rd >>= fun () ->
         respond ~headers ~body:`Empty ~code:`OK)
  >>= function
  | Ok res -> return res
  | Error _ -> respond_error_with_message ~meth ~code:`Not_found "Object not found"

let oid_from_path path =
  match String.rsplit2 path ~on:'/' with
  | Some ("/objects", oid) ->
    if is_sha256_hex_digest oid then `Default_path oid else `Wrong_path
  | Some ("/data/objects", oid) ->
    if is_sha256_hex_digest oid then `Download_path oid else `Wrong_path
  | Some ("", "objects") -> `Post_path
  | _ -> `Wrong_path

(* TODO fix this *)
let fix_uri port uri =
  let uri = Uri.with_scheme uri (Some "http") in
  Uri.with_port uri (if port = 80 then None else Some port)

let handle_get root meth uri =
  let path = Uri.path uri in
  match oid_from_path path with
  | `Default_path oid -> respond_object_metadata ~root ~meth ~uri ~oid
  | `Download_path oid -> respond_object ~root ~meth ~oid
  | `Post_path | `Wrong_path ->
    respond_error_with_message ~meth ~code:`Not_found "Wrong path"

let handle_verify root meth oid =
  check_object_file_stat ~root ~oid
  >>= function
  | Ok _ -> respond_ok ~code:`OK
  | Error _ ->
    respond_error_with_message ~meth ~code:`Not_found
      "Verification failed: object not found"

let handle_post root meth uri body =
  let path = Uri.path uri in
  match oid_from_path path with
  | `Download_path _ | `Wrong_path ->
    respond_error_with_message ~meth ~code:`Not_found "Wrong path"
  | `Default_path oid -> handle_verify root meth oid
  | `Post_path ->
    Body.to_string body >>= fun body ->
    Json.parse_oid_size body >>= function
    | None -> respond_error_with_message ~meth ~code:`Bad_request "Invalid body"
    | Some (oid, size) ->
      check_object_file_stat ~root ~oid >>= function
      | Ok stat when (Unix.Stats.size stat = size) ->
        let url = get_download_url uri oid in
        respond_with_string ~meth ~code:`OK @@ Json.download url
      | Ok _ ->
        respond_error_with_message ~meth ~code:`Bad_request "Wrong object size"
      | Error _ ->
        let url = Uri.with_path uri @@ Filename.concat "/objects" oid in
        respond_with_string ~meth ~code:`Accepted @@ Json.upload url

let handle_put root meth uri body req =
  let path = Uri.path uri in
  let headers = Request.headers req in
  match Header.get_content_range headers with
  | None -> respond_error ~code:`Bad_request
  | Some bytes_to_read ->
    match oid_from_path path with
    | `Download_path _ | `Post_path | `Wrong_path ->
      respond_error_with_message ~meth ~code:`Not_found "Wrong path"
    | `Default_path oid ->
      check_object_file_stat ~root ~oid >>= function
      | Ok _ -> respond_ok ~code:`OK (* already exist *)
      | Error _ ->
        let filename = get_object_filename ~root ~oid in
        let temp_file = get_temp_filename ~root ~oid in
        make_objects_dir_if_needed ~root ~oid >>= fun () ->
        Writer.with_file_atomic ~temp_file ~fsync:true filename ~f:(fun w ->
            let received = ref 0 in
            Pipe.transfer (Body.to_pipe body) (Writer.pipe w) ~f:(fun str ->
                received := !received + (String.length str);
                str) >>= fun () ->
            if (Int64.of_int !received) = bytes_to_read
            then respond_ok ~code:`Created
            else
              let err = sprintf "Incomplete upload of %s" oid in
              failwith err) (* TODO: Remove incomplete temp file *)

let serve_client ~root ~port ~body ~req =
  let uri = Request.uri req in
  let meth = Request.meth req in
  if Option.is_none (Uri.host uri) then
    respond_error_with_message ~meth ~code:`Bad_request "Wrong host"
  else
    let uri = fix_uri port uri in
    match meth with
    | (`GET as meth) | (`HEAD as meth) -> handle_get root meth uri
    | `POST -> handle_post root meth uri body
    | `PUT -> handle_put root meth uri body req
    | _ -> respond_error ~code:`Method_not_allowed

let serve_client_and_log_respond ~root ~port ~logger ~body (`Inet (client_host, _)) req =
  serve_client ~root ~port ~body ~req >>| fun (resp, log_info) ->
  let client_host = UnixLabels.string_of_inet_addr client_host in
  let meth = Code.string_of_method @@ Request.meth req in
  let path = Uri.path @@ Request.uri req in
  let version = Code.string_of_version @@ Request.version req in
  (match log_info with
   | `Log_ok status ->
     let status = Code.string_of_status status in
     Log.info logger "%s \"%s %s %s\" %s" client_host meth path version status
   | `Log_error (status, msg) ->
     let status = Code.string_of_status status in
     Log.error logger "%s \"%s %s %s\" %s \"%s\"" client_host meth path version status msg);
  resp

let determine_mode cert key =
  match (cert, key) with
  | Some c, Some k -> return (`OpenSSL (`Crt_file_path c, `Key_file_path k))
  | None, None -> return `TCP
  | _ ->
      eprintf "Error: must specify both certificate and key for HTTPS\n";
      shutdown 0;
      Deferred.never ()

let start_server ~root ~host ~port ~cert ~key ~verbose () =
  let root = Filename.concat root "/.lfs" in
  mkdir_if_needed root >>= fun () ->
  mkdir_if_needed @@ Filename.concat root "/objects" >>= fun () ->
  mkdir_if_needed @@ Filename.concat root "/temp" >>= fun () ->
  determine_mode cert key >>= fun mode ->
  let mode_str = (match mode with `OpenSSL _ -> "HTTPS" | `TCP -> "HTTP") in
  let logging_level = if verbose then `Info else `Error in
  let logger = Log.create ~output:[Log.Output.stdout ()] ~level:logging_level in
  Log.raw logger "Listening for %s on %s:%d\n%!" mode_str host port;
  Unix.Inet_addr.of_string_or_getbyname host
  >>= fun host ->
  let listen_on = Tcp.Where_to_listen.create
      ~socket_type:Socket.Type.tcp
      ~address:(`Inet (host, port))
      ~listening_on:(fun _ -> port)
  in
  let handle_error address ex =
    match address with
    | `Unix _ -> assert false
    | `Inet (client_host, _) ->
      let client_host = UnixLabels.string_of_inet_addr client_host in
      match Monitor.extract_exn ex with
      | Failure err -> Log.error logger "%s Failure: %s" client_host err
      | Unix.Unix_error (_, err, _) -> Log.error logger "%s Unix_error: %s" client_host err
      | ex -> Log.error logger "%s Exception: %s" client_host (Exn.to_string ex)
  in
  Server.create
    ~on_handler_error:(`Call handle_error)
    ~mode
    listen_on
    (serve_client_and_log_respond ~root ~port ~logger)
  >>= fun _ -> Deferred.never ()

let () =
  Command.async_basic
    ~summary:"Start Git LFS server"
    Command.Spec.(
      empty
      +> anon (maybe_with_default "." ("root" %: string))
      +> flag "-s" (optional_with_default "127.0.0.1" string) ~doc:"address IP address to listen on"
      +> flag "-p" (optional_with_default 8080 int) ~doc:"port TCP port to listen on"
      +> flag "-cert" (optional file) ~doc:"file File of certificate for https"
      +> flag "-key" (optional file) ~doc:"file File of private key for https"
      +> flag "-verbose" (no_arg) ~doc:" Verbose logging"
    )
    (fun root host port cert key verbose ->
       start_server ~root ~host ~port ~cert ~key ~verbose)
  |> fun command -> Command.run ~version:"0.1.1" ~build_info:"Master" command

