(** IRC message parsing. *)

type t = {
  prefix: string option;
  command: string;
  params: string list;
  trail: string option;
}
(** A type representing an IRC message. *)

type parse_result =
  | Message of t
  (** A successfully-parsed message. *)
  | Parse_error of (string * string)
  (** A parse failure, containing the original data and an error message .*)
(** A type representing an attempt to parse a string into an IRC message. *)

val extract_prefix : string -> string option * string
(** Exposed for testing - not intended for use. *)

val extract_trail : string -> string * string option
(** Exposed for testing - not intended for use. *)

val extract_command_and_params : string -> string * string list
(** Exposed for testing - not intended for use. *)

val parse : string -> parse_result
(** Attempt to parse an IRC message. *)
