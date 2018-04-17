(** Generic IRC client library, functorised over the
    {{:Irc_transport.IO.html}Irc_transport.IO} module. *)

module type CLIENT = sig
  module Io : sig
    type 'a t
    type inet_addr
    type config
  end

  type connection_t

  val send : connection:connection_t -> Irc_message.t -> unit Io.t
  (** Send the given message *)

  val send_join : connection:connection_t -> channel:string -> unit Io.t
  (** Send the JOIN command. *)

  val send_nick : connection:connection_t -> nick:string -> unit Io.t
  (** Send the NICK command. *)

  val send_pass : connection:connection_t -> password:string -> unit Io.t
  (** Send the PASS command. *)

  val send_pong : connection:connection_t ->
    message1:string -> message2:string -> unit Io.t
  (** Send the PONG command. *)

  val send_privmsg : connection:connection_t ->
    target:string -> message:string -> unit Io.t
  (** Send the PRIVMSG command. *)

  val send_notice : connection:connection_t ->
    target:string -> message:string -> unit Io.t
  (** Send the NOTICE command. *)

  val send_quit : connection:connection_t -> unit Io.t
  (** Send the QUIT command. *)

  val send_user : connection:connection_t ->
    username:string -> mode:int -> realname:string -> unit Io.t
  (** Send the USER command. *)

  val connect :
    ?username:string -> ?mode:int -> ?realname:string -> ?password:string ->
    ?config:Io.config ->
    addr:Io.inet_addr -> port:int -> nick:string -> unit ->
    connection_t Io.t
  (** Connect to an IRC server at address [addr]. The PASS command will be
      sent if [password] is not None. *)

  val connect_by_name :
    ?username:string -> ?mode:int -> ?realname:string -> ?password:string ->
    ?config:Io.config ->
    server:string -> port:int -> nick:string -> unit ->
    connection_t option Io.t
  (** Try to resolve the [server] name using DNS, otherwise behaves like
      {!connect}. Returns [None] if no IP could be found for the given
      name. *)

  (** Information on keeping the connection alive *)
  type keepalive = {
    mode: [`Active | `Passive];
    timeout: int;
  }

  val default_keepalive : keepalive
  (** Default value for keepalive: active mode with auto-reconnect *)

  val listen :
    ?keepalive:keepalive ->
    connection:connection_t ->
    callback:(
      connection_t ->
      Irc_message.parse_result ->
      unit Io.t) ->
    unit ->
    unit Io.t
  (** [listen connection callback] listens for incoming messages on
      [connection]. All server pings are handled internally; all other
      messages are passed, along with [connection], to [callback].
      @param keepalive the behavior on disconnection (if the transport
        supports {!Irc_transport.IO.pick} and {!Irc_transport.IO.sleep}) *)

  val reconnect_loop :
    ?keepalive:keepalive ->
    ?reconnect:bool ->
    after:int ->
    connect:(unit -> connection_t option Io.t) ->
    f:(connection_t -> unit Io.t) ->
    callback:(
      connection_t ->
      Irc_message.parse_result ->
      unit Io.t) ->
    unit ->
    unit Io.t
  (** A combination of {!connect} and {!listen} that, every time
      the connection is terminated, tries to start a new one
      after [after] seconds.
      @param after time before trying to reconnect
      @param connect how to reconnect
        (a closure over {!connect} or {!connect_by_name})
      @param callback the callback for {!listen}
      @param f the function to call after connection *)

  val set_log : (string -> unit Io.t) -> unit
  (** Set logging function *)
end

module Make : functor (Io: Irc_transport.IO) ->
  CLIENT with type 'a Io.t = 'a Io.t
          and type Io.inet_addr = Io.inet_addr
          and type Io.config = Io.config
