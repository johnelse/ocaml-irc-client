include Irc_client.CLIENT
  with type 'a Io.t = 'a Lwt.t
   and type Io.inet_addr = Lwt_unix.inet_addr
   and type Io.config = unit
