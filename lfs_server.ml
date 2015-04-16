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
open Cohttp_async

let handler ~body:_ _sock req =
  let uri = Cohttp.Request.uri req in
  eprintf "%s\n" (Uri.path uri);
  match Uri.path uri with
  | "/test" ->
    Uri.get_query_param uri "hello"
    |> Option.map ~f:(fun v -> "hello: " ^ v)
    |> Option.value ~default:"No param hello supplied"
    |> Server.respond_with_string
  | _ ->
    Server.respond_with_string ~code:`Not_found "Route not found"

let start_server host port () =
  eprintf "Listening for HTTP on port %d\n" port;
  eprintf "Try 'curl http://localhost:%d/test?hello=xyz'\n%!" port;
  Unix.Inet_addr.of_string_or_getbyname host
  >>= fun host ->
  let listen_on = Tcp.Where_to_listen.create
      ~socket_type:Socket.Type.tcp
      ~address:(`Inet (host, port))
      ~listening_on:(fun _ -> port)
  in
  Server.create ~on_handler_error:`Raise listen_on handler
  >>= fun _ -> Deferred.never ()

let () =
  Command.async_basic
    ~summary:"Start a hello world Async server"
    Command.Spec.(
      empty
      +> flag "-s" (optional_with_default "127.0.0.1" string) ~doc:"address IP address to listen on"
      +> flag "-p" (optional_with_default 8080 int) ~doc:"port TCP port to listen on"
    ) start_server
  |> Command.run

