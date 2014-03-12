type t = {
  prefix: string option;
  command: string;
  params: string list;
  trail: string option;
}

type parse_result =
  | Message of t
  | Parse_error of (string * string)

val extract_prefix : string -> string option * string

val extract_trail : string -> string * string option

val extract_command_and_params : string -> string * string list

val parse : string -> parse_result
