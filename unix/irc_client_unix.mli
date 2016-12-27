module Io_unix : Irc_transport.IO
  with type 'a t = 'a
   and type inet_addr = Unix.inet_addr
   and type file_descr = Unix.file_descr
   and type config = unit

include Irc_client.CLIENT
  with type 'a Io.t = 'a Io_unix.t
   and type Io.inet_addr = Io_unix.inet_addr
   and type Io.config = Io_unix.config
