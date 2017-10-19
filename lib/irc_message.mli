(** IRC message parsing. *)

(** A type representing an IRC command,
    following {{: https://tools.ietf.org/html/rfc2812#section-3} RFC 2812} *)
type command =
  | PASS of string
  | NICK of string
  | USER of string list (** see rfc *)
  | OPER of string * string  (** name * password *)
  | MODE of string * string  (** nick * mode string *)
  | QUIT of string (** quit message *)
  | SQUIT of string * string (** server * comment *)
  | JOIN of string list * string list  (** channels * key list *)
  | JOIN0 (** join 0 (parts all channels) *)
  | PART of string list * string (** channels * comment *)
  | TOPIC of string * string (** chan * topic *)
  | NAMES of string list (** channels *)
  | LIST of string list (** channels *)
  | INVITE of string * string  (** nick * chan *)
  | KICK of string list * string * string (** channels * nick * comment *)
  | PRIVMSG of string * string (** target * message *)
  | NOTICE of string * string (** target * message *)
  | PING of string
  | PONG of string * string
  | Other of string * string list  (** other cases *)

type t = {
  prefix: string option;
  command : command;
}

(** {2 Constructors} *)

val pass : string -> t
val nick : string -> t
val user : username:string -> mode:int -> realname:string -> t
val oper : name:string -> pass:string -> t
val mode : nick:string -> mode:string -> t
val quit : msg:string option -> t
val join : chans:string list -> keys:string list option -> t
val join0 : t
val part : chans:string list -> comment:string option -> t
val topic : chan:string -> topic:string option -> t
val names : chans:string list -> t
val list : chans:string list -> t
val invite : nick:string -> chan:string -> t
val kick : chans:string list -> nick:string -> comment:string option -> t
val privmsg : target:string -> string -> t
val notice : target:string -> string -> t
val ping : string -> t
val pong : middle:string -> trailer:string -> t

val other : cmd:string -> params:string list -> t

(** {2 Printing} *)

val to_string : t -> string
(** Format the message into a string that can be sent on IRC *)

val output : out_channel -> t -> unit

val write_buf : Buffer.t -> t -> unit

(** {2 Parsing} *)

type 'a or_error = ('a, string) Result.result

type parse_result = t or_error

exception ParseError of string * string

val parse : string -> t or_error
(** Attempt to parse an IRC message. *)

val parse_exn : string -> t
(** [parse_exn s] returns the parsed message
    @raise ParseError if the string is not a proper message *)

(** {2 Low level Functions -- testing} *)

val extract_prefix : string -> string option * string
(** Exposed for testing - not intended for use. *)

val extract_trail : string -> string * string option
(** Exposed for testing - not intended for use. *)
