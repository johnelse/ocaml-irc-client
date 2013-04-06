external (|>) : 'a -> ('a -> 'b) -> 'b = "%revapply"

let split ~str ~c =
  let rec rev_split' ~str ~c ~acc =
    try
      let index = String.index str c in
      let before = String.sub str 0 index in
      let after = String.sub str (index + 1) (String.length str - index - 1) in
      rev_split' ~str:after ~c ~acc:(before :: acc)
    with Not_found ->
      str :: acc
  in
  List.rev (rev_split' ~str ~c ~acc:[])

let get_whole_lines ~str =
  let lines =
    split ~str ~c:'\n'
    |> List.map String.trim
  in
  let lines_reversed = List.rev lines in
  (* Get the list of all lines except the last. *)
  let whole_lines = List.rev (List.tl lines_reversed) in
  (* Get the last line, which may be partial. *)
  let rest = List.hd lines_reversed in
  whole_lines, rest

let handle_input ~buffer ~input =
  (* Append the new input to the buffer. *)
  Buffer.add_substring buffer input 0 (String.length input);
  let whole_lines, rest = get_whole_lines (Buffer.contents buffer) in
  (* Replace the buffer contents with the last, partial, line. *)
  Buffer.reset buffer;
  Buffer.add_string buffer rest;
  (* Return the whole lines extracted from the buffer. *)
  whole_lines
