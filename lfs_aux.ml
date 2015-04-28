
open Core.Std
open Async.Std
module Core_unix = Core.Std.Unix

module SHA256 : sig

  type t

  val create : unit -> t
  val feed : t -> string -> unit
  val hexdigest : t -> string

end = struct

  type t = { hash: Cryptokit.hash; mutable valid: bool }

  let create () = { hash = Cryptokit.Hash.sha256 (); valid = true }

  let feed t str =
    if not t.valid then failwith "Wrong SHA256 internal state"
    else
      t.hash#add_string str

  let hexdigest t =
    if not t.valid then failwith "Wrong SHA256 internal state"
    else
      t.valid <- false;
    let sum = t.hash#result in
    Cryptokit.transform_string (Cryptokit.Hexa.encode ()) sum
end

let getumask () =
  let umask = Core_unix.umask 0 in
  ignore (Core_unix.umask umask);
  umask

let with_file_atomic ?temp_file file ~f =
  Unix.mkstemp (Option.value temp_file ~default:file)
  >>= fun (temp_file, fd) ->
  let t = Writer.create fd in
  Writer.with_close t ~f:(fun () ->
      f t
      >>= fun result ->
      let perm = 0o666 land (lnot (getumask ())) in
      Unix.fchmod fd ~perm
      >>= fun () ->
      Writer.fsync t (* make sure file content is flushed to disk *)
      >>| fun () ->
      result)
  >>= function
  | Error _ as result ->
    don't_wait_for (Unix.unlink temp_file);
    return result
  | Ok _ as result ->
    Monitor.try_with (fun () -> Unix.rename ~src:temp_file ~dst:file)
    >>| function
    | Ok () -> result
    | Error exn ->
      don't_wait_for (Unix.unlink temp_file);
      failwiths "with_file_atomic could not create file"
        (file, exn) <:sexp_of< string * exn >>

