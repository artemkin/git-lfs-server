
open Core.Std
open Async.Std

let run () =
  let input = Filename.concat "." Sys.argv.(1) in
  let output = Filename.concat "." Sys.argv.(2) in
  Reader.with_file input ~f:(fun r ->
    Writer.with_file output ~f:(fun w ->
        Pipe.transfer_id (Reader.pipe r) (Writer.pipe w)))
  >>| fun () -> (Shutdown.shutdown 0)

let () =
  every (Time.Span.create ~sec:1 ()) (fun () ->
    eprintf "Mem %f\n" (Gc.allocated_bytes ()));
  ignore (run ());
  never_returns (Scheduler.go ())

