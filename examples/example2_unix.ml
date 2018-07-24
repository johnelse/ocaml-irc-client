module C = Irc_client_unix
module M = Irc_message

let host = ref "irc.freenode.net"
let port = ref 6667
let nick = ref "bobobobot"
let channel = ref "#demo_irc"
let message = "Hello, world!  This is a test from ocaml-irc-client"

let callback connection result =
  match result with
  | Result.Ok ({M.command=M.Other _ ; _}as msg) ->
    Printf.printf "Got unknown message: %s\n" (M.to_string msg);
    flush stdout;
  | Result.Ok ({M.command=M.PRIVMSG (target, data); _} as msg) ->
    Printf.printf "Got message: %s\n" (M.to_string msg);
    flush stdout;
    C.send_privmsg ~connection ~target ~message:("ack: " ^ data);
  | Result.Ok msg ->
    Printf.printf "Got message: %s\n" (M.to_string msg);
    flush stdout;
  | Result.Error e ->
    print_endline e

let main () =
  C.set_log print_endline;
  C.reconnect_loop
    ~after:30
    ~connect:(fun () ->
      print_endline "Connecting...";
      C.connect_by_name ~server:!host ~port:!port ~nick:!nick ()
    )
    ~f:(fun connection ->
      print_endline "Connected";
      Printf.printf "send join msg for `%s`\n" !channel;
      C.send_join ~connection ~channel:!channel;
      C.send_privmsg ~connection ~target:!channel ~message
    )
    ~callback
    ()

let options = Arg.align
  [ "-host", Arg.Set_string host, " set remove server host name"
  ; "-port", Arg.Set_int port, " set remote server port"
  ; "-chan", Arg.Set_string channel, " channel to join"
  ]

let _ =
  Arg.parse options (fun _ -> ()) "example2 [options]";
  main ()

(* ocamlfind ocamlopt -package irc-client.unix -linkpkg code.ml *)
