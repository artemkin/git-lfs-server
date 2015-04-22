
open Core.Std
open Async.Std
open Cohttp
open Cohttp_async

let handle_put uri body =
  let path = Uri.path uri in
  try_with (fun () ->
    let filename = Filename.concat "." path in
      Writer.with_file filename ~f:(fun w ->
          Pipe.transfer_id (Body.to_pipe body) (Writer.pipe w)))
  >>= function
  | Ok _ -> Server.respond `Created
  | Error _ -> Server.respond `Internal_server_error

let serve_client ~body _sock req =
  let uri = Request.uri req in
  match Request.meth req with
  | `PUT -> handle_put uri body
  | _ -> Server.respond `Method_not_allowed

let start_server ~host ~port () =
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
    (serve_client)
  >>= fun _ -> Deferred.never ()

let () =
  every (Time.Span.create ~sec:3 ()) (fun () ->
    Gc.full_major ();
    let stat = Gc.stat () in
    let used = stat.live_words in
    eprintf "(Used %d) (Alloc %f)\n" used (Gc.allocated_bytes ())
    );
  ignore (start_server ~host:"localhost" ~port:8080 ());
  never_returns (Scheduler.go ())

