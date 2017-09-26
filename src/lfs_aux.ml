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

open Core
open Async
module Core_unix = Core.Unix

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

let is_sha256_hex_digest str =
  if String.length str <> 64 then false
  else String.for_all str ~f:(fun ch -> Char.(is_lowercase ch || is_digit ch))

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
    | Error _ (* exn *) ->
      don't_wait_for (Unix.unlink temp_file);
      failwith "with_file_atomic could not create file"
(* FIXME        (file, exn) <:sexp_of< string * exn >> *)

