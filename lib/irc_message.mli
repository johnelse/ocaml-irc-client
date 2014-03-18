(** IRC message parsing. *)

type t = {
  prefix: string option;
  command: string;
  params: string list;
  trail: string option;
}
(** A type representing an IRC message. *)

type parse_error =
  | ZeroLengthMessage
  (** Attempted to parse an empty string. *)
(** A type representing the errors which can result when attempting to parse
    an IRC message. *)

val string_of_error : parse_error -> string
(** Convert a parse_error to a string. *)

val extract_prefix : string -> string option * string
(** Exposed for testing - not intended for use. *)

val extract_trail : string -> string * string option
(** Exposed for testing - not intended for use. *)

val extract_command_and_params : string -> string * string list
(** Exposed for testing - not intended for use. *)

val parse : string -> (t, (string * parse_error)) Irc_result.t
(** Attempt to parse an IRC message. On failure, the original message will be
    returning, along with a {{:#TYPEparse_error}parse_error}. *)
