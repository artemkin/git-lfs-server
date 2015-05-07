#!/usr/bin/env ocaml

#use "test.ml"

let request = {|
LINK /objects/ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39 HTTP/1.1
Host: localhost

|}

let response = {|
HTTP/1.1 405 Method Not Allowed
connection: keep-alive
content-length: 0

|}

let () =
  Test.netcat request response

