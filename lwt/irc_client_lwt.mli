type connection_t

val send_join : connection:connection_t -> channel:string -> unit Lwt.t

val send_nick : connection:connection_t -> nick:string -> unit Lwt.t

val send_pass : connection:connection_t -> password:string -> unit Lwt.t

val send_pong : connection:connection_t -> message:string -> unit Lwt.t

val send_privmsg : connection:connection_t ->
  target:string -> message:string -> unit Lwt.t

val send_notice : connection:connection_t ->
  target:string -> message:string -> unit Lwt.t

val send_quit : connection:connection_t -> unit Lwt.t

val send_user : connection:connection_t ->
  username:string -> mode:int -> realname:string -> unit Lwt.t

val connect :
  ?username:string -> ?mode:int -> ?realname:string -> ?password:string -> 
  addr:Lwt_unix.inet_addr -> port:int -> nick:string -> unit ->
  connection_t Lwt.t

val connect_by_name :
  ?username:string -> ?mode:int -> ?realname:string -> ?password:string ->
  server:string -> port:int -> nick:string -> unit ->
  connection_t option Lwt.t

val listen : connection:connection_t ->
  callback:(
    connection_t ->
    Irc_message.parse_result ->
    unit Lwt.t
  ) ->
  unit Lwt.t
