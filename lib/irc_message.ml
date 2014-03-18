type t = {
  prefix: string option;
  command: string;
  params: string list;
  trail: string option;
}

type parse_error =
  | ZeroLengthMessage

let string_of_error = function
  | ZeroLengthMessage -> "ZeroLengthMessage"

let extract_prefix str =
  if str.[0] = ':'
  then begin
    let prefix_length = (String.index str ' ') - 1 in
    Some (String.sub str 1 prefix_length),
    (String.sub str
      (prefix_length + 2)
      ((String.length str) - (prefix_length + 2)))
  end else
    None, str

let extract_trail str =
  try
    let trail_start = (String.index str ':') + 1 in
    let trail_length = (String.length str) - trail_start in
    (String.sub str 0 (trail_start - 2)),
    Some (String.sub str trail_start trail_length)
  with Not_found ->
    str, None

let extract_command_and_params str =
  let words = Irc_helpers.split ~str ~c:' ' in
  (List.hd words), (List.tl words)

let parse message =
  if String.length message = 0
  then `Error (message, ZeroLengthMessage)
  else begin
    let prefix, rest = extract_prefix message in
    let rest, trail = extract_trail rest in
    let command, params = extract_command_and_params rest in
    `Ok {
      prefix;
      command;
      params;
      trail;
    }
  end
