module Make : functor (Io: Irc_transport.IO) ->
  sig
    type connection_t

    val send_join : connection:connection_t -> channel:string -> unit Io.t
    val send_nick : connection:connection_t -> nick:string -> unit Io.t
    val send_pass : connection:connection_t -> password:string -> unit Io.t
    val send_pong : connection:connection_t -> message:string -> unit Io.t
    val send_privmsg : connection:connection_t ->
      target:string -> message:string -> unit Io.t
    val send_quit : connection:connection_t -> unit Io.t
    val send_user : connection:connection_t ->
      username:string -> mode:int -> realname:string -> unit Io.t

    val connect : server:string -> port:int -> username:string -> mode:int ->
      realname:string -> nick:string -> password:string -> connection_t Io.t

    val listen : connection:connection_t ->
      callback:(string -> unit Io.t) -> unit Io.t
  end
