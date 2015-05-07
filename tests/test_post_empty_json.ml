#!/usr/bin/env ocaml

#use "test.ml"

let request = {|
POST /objects HTTP/1.1
Host: localhost

|}

let response = {|
HTTP/1.1 400 Bad Request
connection: keep-alive
content-length: 29
content-type: application/vnd.git-lfs+json

{ "message": "Invalid body" }
|}

let () =
  Test.netcat request response

