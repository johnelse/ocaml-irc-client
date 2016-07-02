module Io : Irc_transport.IO
  with type 'a t = 'a Lwt.t
   and type inet_addr = Lwt_unix.inet_addr
   and type file_descr = Lwt_ssl.socket

include module type of Irc_client.Make(Io)

