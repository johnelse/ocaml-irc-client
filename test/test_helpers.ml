open OUnit2

module H = Irc_helpers

let pp_strlist l = "[" ^ String.concat ";" l ^ "]"

let test_split =
  let test1 _ =
    assert_equal ~printer:pp_strlist
      ["ab"; "c"; "d"; "ef"]
      (H.split ~str:"ab c d ef" ~c:' ')
  and test2 _ =
    assert_equal ~printer:pp_strlist
      [""; "a"; ""; "b"; "hello"; "world"; ""]
      (H.split ~str:" a  b hello world " ~c:' ')
  in
  "test_split" >:::  [ "1" >:: test1; "2" >:: test2 ]

let test_handle_input =
  let test buffer_contents input (expected_lines, expected_buffer) =
    let buffer = Buffer.create 0 in
    Buffer.add_string buffer buffer_contents;
    assert_equal ~printer:pp_strlist
      expected_lines
      (H.handle_input ~buffer ~input);
    assert_equal
      expected_buffer
      (Buffer.contents buffer)
  in
  "test_handle_input" >:::
    (List.map
      (fun (name, buffer_contents, input, expected_output) ->
        (name >::(fun _ -> test buffer_contents input expected_output)))
      [
        (
          "empty", "", "",
          ([], "")
        );
        (
          "no newline", "", "foo",
          ([], "foo")
        );
        (
          "one newline", "", "foo\r\n",
          (["foo"], "")
        );
        (
          "one newline plus extra", "foo", "bar\r\nbaz",
          (["foobar"], "baz")
        );
        (
          "two newlines", "", "foo\r\nbaz\r\n",
          (["foo"; "baz"], "")
        );
      ])

let suite =
  "test_helpers" >:::
    [
      test_split;
      test_handle_input;
    ]
