#!/usr/bin/env ocaml

#use "test.ml"

let request = {|
GET /objects/ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39 HTTP/1.1

|}

let response = {|
HTTP/1.1 400 Bad Request
connection: keep-alive
content-length: 27
content-type: application/vnd.git-lfs+json

{ "message": "Wrong host" }
|}

let () =
  Test.netcat request response

