
module Io_tls : sig
  type 'a t = 'a Lwt.t

  type file_descr = {
    ic: Tls_lwt.ic;
    oc: Tls_lwt.oc;
  }

  type config = Tls.Config.client

  val default_config : Tls.Config.client
  (** Default config. No authentication, only secure connection. *)

  include Irc_transport.IO
    with type 'a t := 'a t
     and type inet_addr = string
     and type file_descr := file_descr
     and type config := config
end

include Irc_client.CLIENT
  with type 'a Io.t = 'a Io_tls.t
   and type Io.inet_addr = Io_tls.inet_addr
   and type Io.config = Io_tls.config
