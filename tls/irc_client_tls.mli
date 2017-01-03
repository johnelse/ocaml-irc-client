
module Io : sig
  type 'a t = 'a Lwt.t

  type file_descr = {
    ic: Tls_lwt.ic;
    oc: Tls_lwt.oc;
  }

  val default_config : Tls.Config.client
  (** Default config. No authentication, only secure connection. *)

  val config : Tls.Config.client ref
  (** Current configuration, used by {!connect} to set the TLS parameters. *)

  include Irc_transport.IO
    with type 'a t := 'a t
     and type inet_addr = string
     and type file_descr := file_descr
end

include module type of Irc_client.Make(Io)
