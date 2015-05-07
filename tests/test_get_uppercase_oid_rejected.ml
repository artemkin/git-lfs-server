#!/usr/bin/env ocaml

#use "test.ml"

let request = {|
GET /objects/EBDAA749534BBBF8E1FC02C4F634648D749D5401E09B11FEFBE283FE913B7D39 HTTP/1.1
Host: localhost

|}

let response = {|
HTTP/1.1 404 Not Found
connection: keep-alive
content-length: 27
content-type: application/vnd.git-lfs+json

{ "message": "Wrong path" }
|}

let () =
  Test.netcat request response

