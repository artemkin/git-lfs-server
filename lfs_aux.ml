

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

