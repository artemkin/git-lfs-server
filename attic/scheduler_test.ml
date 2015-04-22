
open Core.Std
open Async.Std

let () =
  every (Time.Span.create ~sec:1 ()) (fun () ->
    eprintf "(Alloc %f)\n" (Gc.allocated_bytes ())
    );
  never_returns (Scheduler.go ())

