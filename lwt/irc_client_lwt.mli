module Io_lwt : Irc_transport.IO
  with type 'a t = 'a Lwt.t
   and type inet_addr = Lwt_unix.inet_addr
   and type file_descr = Lwt_unix.file_descr
   and type config = unit

include Irc_client.CLIENT
  with type 'a Io.t = 'a Io_lwt.t
   and type Io.inet_addr = Io_lwt.inet_addr
   and type Io.config = Io_lwt.config
