open OUnit

let test_extract_prefix =
  let test ~msg ~input ~expected_output () =
    let parsed = Irc_message.extract_prefix input in
    assert_equal ~msg parsed expected_output
  in
  "test_extract_prefix" >:::
    [
      "test_no_prefix" >::
        test ~msg:"Parsing a message with no prefix"
          ~input:"PING :server.com"
          ~expected_output:(None, "PING :server.com");
      "test_prefix" >::
        test ~msg:"Parsing a message with a prefix"
          ~input:":nick!user@host PRIVMSG destnick :abc def"
          ~expected_output:(Some "nick!user@host", "PRIVMSG destnick :abc def");
    ]

let test_extract_trail =
  let test ~msg ~input ~expected_output () =
    let parsed = Irc_message.extract_trail input in
    assert_equal ~msg parsed expected_output
  in
  "test_extract_trail" >:::
    [
      "test_no_trail" >::
        test ~msg:"Parsing a message with no trail"
          ~input:"PING"
          ~expected_output:("PING", None);
      "test_trail1" >::
        test ~msg:"Parsing a message with a trail"
          ~input:"PING :irc.domain.com"
          ~expected_output:("PING", Some "irc.domain.com");
      "test_trail2" >::
        test ~msg:"Parsing a message with a trail and parameters"
          ~input:"PRIVMSG destnick :hi there"
          ~expected_output:("PRIVMSG destnick", Some "hi there");
    ]

let test_extract_command_and_params =
  let test ~msg ~input ~expected_output () =
    let parsed = Irc_message.extract_command_and_params input in
    assert_equal ~msg parsed expected_output
  in
  "test_extract_command_and_params" >:::
    [
      "test_no_params" >::
        test ~msg:"Parsing a message with no params"
          ~input:"PING"
          ~expected_output:("PING", []);
      "test_params" >::
        test ~msg:"Parsing a message with params"
          ~input:"PRIVMSG destnick"
          ~expected_output:("PRIVMSG", ["destnick"]);
    ]

let test_full_parser =
  let test ~msg ~input ~expected_output () =
    let parsed = Irc_message.parse input in
    assert_equal ~msg parsed expected_output
  in
  "test_full_parser" >:::
    [
      "test_parse_ping" >::
        test ~msg:"Parsing a PING message"
          ~input:"PING :abc.def"
          ~expected_output:(`Ok {
            Irc_message.prefix = None;
            command = "PING";
            params = [];
            trail = Some "abc.def";
          });
      "test_parse_privmsg" >::
        test ~msg:"Parsing a PRIVMSG"
          ~input:":nick!user@host.com PRIVMSG #channel :Hello all"
          ~expected_output:(`Ok {
            Irc_message.prefix = Some "nick!user@host.com";
            command = "PRIVMSG";
            params = ["#channel"];
            trail = Some "Hello all";
          });
    ]

let base_suite =
  "base_suite" >:::
    [
      test_extract_prefix;
      test_extract_trail;
      test_extract_command_and_params;
      test_full_parser;
    ]

let _ = run_test_tt_main base_suite
