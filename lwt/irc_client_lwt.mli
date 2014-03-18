module Client : sig
  type connection_t

  val send_join : connection:connection_t -> channel:string -> unit Lwt.t

  val send_nick : connection:connection_t -> nick:string -> unit Lwt.t

  val send_pass : connection:connection_t -> password:string -> unit Lwt.t

  val send_pong : connection:connection_t -> message:string -> unit Lwt.t

  val send_privmsg : connection:connection_t ->
    target:string -> message:string -> unit Lwt.t

  val send_quit : connection:connection_t -> unit Lwt.t

  val send_user : connection:connection_t ->
    username:string -> mode:int -> realname:string -> unit Lwt.t

  val connect : addr:Lwt_unix.inet_addr -> port:int -> username:string ->
    mode:int -> realname:string -> nick:string -> ?password:string -> unit ->
    connection_t Lwt.t

  val connect_by_name : server:string -> port:int -> username:string ->
    mode:int -> realname:string -> nick:string -> ?password:string -> unit ->
    (connection_t, Irc_client.connect_error) Irc_result.t Lwt.t

  val listen : connection:connection_t ->
    callback:(
      connection:connection_t ->
      result:(Irc_message.t, string * Irc_message.parse_error) Irc_result.t ->
      unit Lwt.t
    ) ->
    unit Lwt.t
end
