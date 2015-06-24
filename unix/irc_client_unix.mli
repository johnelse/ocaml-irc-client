module Io : Irc_transport.IO
  with type 'a t = 'a
   and type inet_addr = Unix.inet_addr
   and type file_descr = Unix.file_descr

include module type of Irc_client.Make(Io)
