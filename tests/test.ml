
(*TODO print diff *)

let drop_first ~ch s =
  if s.[0] <> ch then s else String.sub s 1 (String.length s - 1)

let drop_last ~ch s =
  let len = String.length s in
  if s.[len - 1] <> ch then s else String.sub s 0 (len - 1)

let run request response =
  request |> drop_first ~ch:'\n' |> fun request ->
  response |> drop_first ~ch:'\n' |> drop_last ~ch:'\n' |> fun response ->
  let fd_in, fd_out = Unix.open_process "nc 127.0.0.1 8080" in
  output_bytes fd_out request;
  flush fd_out;
  let len = 1000 * 1024 in
  let buf = Bytes.make len '\000' in
  let read_bytes = input fd_in buf 0 len in
  let error msg =
    Printf.eprintf "%s\n%!" msg;
    exit 1
  in
  match Unix.close_process (fd_in, fd_out) with
  | Unix.WSTOPPED _ | Unix.WSIGNALED _ -> error "Process stopped/signaled"
  | Unix.WEXITED code when code <> 0 -> error "Wrong exit code"
  | Unix.WEXITED _ ->
    let response' = String.sub buf 0 read_bytes in
    if response <> response' then error "Wrong response"

