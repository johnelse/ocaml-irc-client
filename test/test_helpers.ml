open OUnit

module H = Irc_helpers

let pp_strlist l = "[" ^ String.concat ";" l ^ "]"

let test_split =
  let test1 () =
    assert_equal ~printer:pp_strlist
      ["ab"; "c"; "d"; "ef"]
      (H.split ~str:"ab c d ef" ~c:' ')
  and test2 () =
    assert_equal ~printer:pp_strlist
      [""; "a"; ""; "b"; "hello"; "world"; ""]
      (H.split ~str:" a  b hello world " ~c:' ')
  in
  "test_split" >:::  [ "1" >:: test1; "2" >:: test2 ]

let suite =
  "test_helpers" >:::
    [
      test_split;
    ]
