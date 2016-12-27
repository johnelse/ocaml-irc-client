include Irc_client.CLIENT
  with type 'a Io.t = 'a Lwt.t
   and type Io.inet_addr = string
   and type Io.config = Tls.Config.client
