#!/usr/bin/env ocaml

#use "topfind"
#thread
#require "diff"

module Test : sig

  val netcat: string -> string -> unit

end = struct

  let drop_first_lf s =
    if s.[0] <> '\n' then s else String.sub s 1 (String.length s - 1)

  let drop_last_lf s =
    let len = String.length s in
    let last = s.[len - 1] = '\n' in
    let before_last = len > 1 && s.[len - 2] = '\r' in
    if (not last) || before_last then s else String.sub s 0 (len - 1)

  let get_diff a b = Odiff.string_of_diffs (Odiff.strings_diffs a b)

  let netcat request response =
    request |> drop_first_lf |> fun request ->
    response |> drop_first_lf |> drop_last_lf |> fun response ->
    let fd_in, fd_out = Unix.open_process "nc 127.0.0.1 8080" in
    output_bytes fd_out request;
    flush fd_out;
    Thread.delay 0.1; (* TODO wait for process completion *)
    let len = 1000 * 1024 in
    let buf = Bytes.make len '\000' in
    let read_bytes = input fd_in buf 0 len in
    let error msg =
      Printf.eprintf "%s: %s\n%!" Sys.argv.(0) msg;
      exit 1
    in
    match Unix.close_process (fd_in, fd_out) with
    | Unix.WSTOPPED _ | Unix.WSIGNALED _ -> error "Process stopped/signaled"
    | Unix.WEXITED code when code <> 0 -> error "Wrong exit code"
    | Unix.WEXITED _ ->
      let response' = String.sub buf 0 read_bytes in
      if response <> response' then
        error ("Wrong response\n\n" ^ (get_diff response response'))

end

