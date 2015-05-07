#!/usr/bin/env ocaml

#use "test.ml"

let request = {|
POST /objects HTTP/1.1
Host: localhost
Accept: application/vnd.git-lfs+json
Content-Type: application/vnd.git-lfs+json
Content-Length: 95

{
"oid" : "73bcc5e2fdb23b560e112be22c901379bf9ce3a1f9ca32acd92bc6ba5667a0ae",
"size" : 7170
}

|}

let response = {|
HTTP/1.1 202 Accepted
connection: keep-alive
content-length: 304
content-type: application/vnd.git-lfs+json

{
  "_links": {
    "upload": {
      "href":
        "http://localhost:8080/objects/73bcc5e2fdb23b560e112be22c901379bf9ce3a1f9ca32acd92bc6ba5667a0ae"
    },
    "verify": {
      "href":
        "http://localhost:8080/objects/73bcc5e2fdb23b560e112be22c901379bf9ce3a1f9ca32acd92bc6ba5667a0ae"
    }
  }
}
|}

let () =
  Test.netcat request response

