module Make(Params: sig
    val check_certificate: bool
    val ssl_protocol: Ssl.protocol
  end) : sig
  module Io:Irc_transport.IO
    with type 'a t = 'a Lwt.t
     and type inet_addr = Lwt_unix.inet_addr
     and type file_descr = Lwt_ssl.socket


  include module type of Irc_client.Make(Io)
end
