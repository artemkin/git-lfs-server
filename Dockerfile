# Create image
# docker build -t git-lfs-server .

# Create container
# docker run -it --name git-lfs-server -u test -v `pwd`:/home/test/git-lfs-server git-lfs-server

FROM ubuntu:trusty

MAINTAINER Stanislav Artemkin

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -qq software-properties-common

RUN echo "yes" | add-apt-repository ppa:avsm/ppa
RUN apt-get update

RUN apt-get install -qq apt-utils
RUN apt-get install -qq man
RUN apt-get install -qq sudo
RUN apt-get install -qq m4 pkg-config libssl-dev libgmp-dev
RUN apt-get install -qq curl
RUN apt-get install -qq make
RUN apt-get install -qq git
RUN apt-get install -qq g++
RUN apt-get install -qq unzip
RUN apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam

# pam-devel on CentOS
RUN apt-get install -qq libpam0g-dev

# Create user
RUN adduser test --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
RUN echo "test:test" | chpasswd
RUN echo "test    ALL=(ALL:ALL) ALL" >> /etc/sudoers

RUN su - test -c 'echo export OPAMYES=1 >> ~/.profile'
RUN su - test -c 'opam init'
RUN su - test -c 'opam switch 4.04.2'
RUN su - test -c 'opam update'
RUN su - test -c 'opam install async async_ssl cohttp cohttp-async cryptokit yojson simple_pam utop'
RUN su - test -c 'opam install bisect ocveralls ocamldiff'

