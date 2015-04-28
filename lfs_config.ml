

let version = "0.2.0"

let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "version"
  then Printf.printf "%s" version
  else ()

