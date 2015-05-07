#!/usr/bin/env ocaml

#use "test.ml"

let request = {|
GET /data/objects/ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39 HTTP/1.1
Host: localhost

|}

let response = {|
HTTP/1.1 200 OK
connection: keep-alive
content-type: application/octet-stream
transfer-encoding: chunked

ffa
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

module Json = struct
  let error msg =
    let msg = `Assoc [ "message", `String msg ] in
    Yojson.Basic.pretty_to_string msg

  let metadata ~oid ~size ~self_url ~download_url =
    let msg = `Assoc [
        "oid", `String oid;
        "size", `Int size;
        "_links", `Assoc [
          "self", `Assoc [ "href", `String self_url ];
          "download", `Assoc [ "href", `String download_url ]
        ]
      ] in
    Yojson.Basic.pretty_to_string msg
end

let is_sha256_hex_digest str =
  if String.length str <> 64 then false
  else String.for_all str ~f:Char.is_alphanum

let respond_with_string ?(headers=Header.init ()) =
  let headers = Header.add headers "Content-Type" "application/vnd.git-lfs+json" in
  Server.respond_with_string ~headers

let respond_not_found ~msg =
  respond_with_string
    ~code:`Not_found @@ Json.error msg

let respond_not_implemented () =
  respond_with_string
    ~code:`Not_implemented @@ Json.error "Not implemented"

let get_oid_path ~oid =
  let oid02 = String.prefix oid 2 in
  let oid24 = String.sub oid ~pos:2 ~len:2 in
  Filename.of_parts [oid02; oid24; oid]

let get_object_path ~root ~oid =
  Filename.of_parts [root; "/data/objects"; get_oid_path ~oid]

let respond_object_metadata ~root ~meth ~oid  =
  let file = get_object_path ~root ~oid in
  Unix.access file [`Exists;`Read] >>= function
  | Error _ -> respond_not_found ~msg:"Object not found"
  | Ok _ ->
    respond_with_string ~code:`OK
    @@ Json.metadata ~oid ~size:12345 ~self_url:"self_url" ~download_url:"download_url"

let oid_from_path path =
  match String.rsplit2 path ~on:'/' with
  | Some ("/objects", oid) ->
    if is_sha256_hex_digest oid then Some (oid, `Metadata) else None
  | Some ("/data/objects", oid) ->
    if is_sha256_hex_digest oid then Some (oid, `Object) else None
  | _ -> None

let serve_client ~root ~body:_ _sock req =
  let uri = Request.uri req in
  let path = Uri.path uri in
  let meth = Request.meth req in
  let oid = oid_from_path path in
  match meth, oid with
  | `GET, Some (oid, `Metadata) | `HEAD, Some (oid, `Metadata) ->
    respond_object_metadata ~root ~meth ~oid
  | `GET, Some (oid, `Object) | `HEAD, Some (oid, `Object) ->
    respond_not_implemented ()
  | `GET, None | `HEAD, None -> respond_not_found ~msg:"Wrong path"
  | `POST, _ -> respond_not_implemented ()
  | _ -> respond_not_implemented ()

let start_server ~root ~host ~port () =
  eprintf "Listening for HTTP on port %d\n" port;
  Unix.Inet_addr.of_string_or_getbyname host
  >>= fun host ->
  let listen_on = Tcp.Where_to_listen.create
      ~socket_type:Socket.Type.tcp
      ~address:(`Inet (host, port))
      ~listening_on:(fun _ -> port)
  in
  Server.create
    ~on_handler_error:`Raise
    listen_on
    (serve_client ~root)
  >>= fun _ -> Deferred.never ()

let () =
  Command.async_basic
    ~summary:"Start a Git LFS server"
    Command.Spec.(
      empty
      +> anon (maybe_with_default "./lfs" ("root" %: string))
      +> flag "-s" (optional_with_default "127.0.0.1" string) ~doc:"address IP address to listen on"
      +> flag "-p" (optional_with_default 8080 int) ~doc:"port TCP port to listen on"
    )
    (fun root host port -> start_server ~root ~host ~port)
  |> Command.run


0

|}

let () =
  Test.netcat request response

