include Irc_client.CLIENT
  with type 'a Io.t = 'a
   and type Io.inet_addr = Unix.inet_addr
   and type Io.config  = unit
