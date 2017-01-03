module Io : Irc_transport.IO
  with type 'a t = 'a Lwt.t
   and type inet_addr = Lwt_unix.inet_addr
   and type file_descr = Lwt_unix.file_descr
   and type config = unit

include module type of Irc_client.Make(Io)

