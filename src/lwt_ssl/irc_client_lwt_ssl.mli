module Config : sig
  type t = {
    check_certificate: bool;
    proto: Ssl.protocol;
  }

  val default : t
end

include Irc_client.CLIENT
  with type 'a Io.t = 'a Lwt.t
   and type Io.inet_addr = Lwt_unix.inet_addr
   and type Io.config = Config.t
