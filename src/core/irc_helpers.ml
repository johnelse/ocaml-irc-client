let split ~str ~c =
  (* [i]: current index in [str]
     [acc]: list of strings split so far *)
  let rec rev_split' ~str ~i ~c ~acc =
    try
      let index = String.index_from str i c in
      let before = String.sub str i (index-i) in
      rev_split' ~str ~c ~i:(index+1) ~acc:(before :: acc)
    with Not_found ->
      String.sub str i (String.length str - i) :: acc
  in
  List.rev (rev_split' ~str ~i:0 ~c ~acc:[])

let split1_exn ~str ~c =
  let index = String.index str c in
  let before = String.sub str 0 index in
  let after = String.sub str (index + 1) (String.length str - index - 1) in
  before, after

let get_whole_lines ~str =
  let rec find i acc =
    try
      let j = String.index_from str i '\n' in
      if i=j then find (j+1) acc
      else
        let line = String.sub str i (j-i-1) in
        find (j+1) (line :: acc)
    with Not_found ->
      if i=String.length str
      then List.rev acc, `NoRest
      else List.rev acc, `Rest (String.sub str i (String.length str - i))
  in
  find 0 []

let handle_input ~buffer ~input =
  (* Append the new input to the buffer. *)
  Buffer.add_string buffer input;
  let whole_lines, rest = get_whole_lines ~str:(Buffer.contents buffer) in
  (* Replace the buffer contents with the last, partial, line. *)
  Buffer.clear buffer;
  begin match rest with
    | `NoRest -> ()
    | `Rest s -> Buffer.add_string buffer s;
  end;
  (* Return the whole lines extracted from the buffer. *)
  whole_lines

