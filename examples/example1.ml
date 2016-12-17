open Lwt
module C = Irc_client_lwt

let host = "localhost"
let port = 6667
let realname = "Demo IRC bot"
let nick = "demoirc"
let username = nick
let channel = "#demo_irc"
let message = "Hello, world!  This is a test from ocaml-irc-client"

let string_opt_to_string = function
  | None -> "None"
  | Some s -> Printf.sprintf "Some %s" s

let string_list_to_string string_list =
  Printf.sprintf "[%s]" (String.concat "; " string_list)

let callback _connection result =
  let open Irc_message in
  match result with
  | Result.Ok msg ->
    Lwt_io.printf "Got message: %s\n" (to_string msg)
  | Result.Error e ->
    Lwt_io.printl e

let lwt_main =
  Lwt_unix.gethostbyname host
  >>= fun he -> C.connect ~addr:(he.Lwt_unix.h_addr_list.(0))
                  ~port ~username ~mode:0 ~realname ~nick ()
  >>= fun connection -> Lwt_io.printl "Connected"
  >>= fun () -> C.send_join ~connection ~channel
  >>= fun () -> C.send_privmsg ~connection ~target:channel ~message
  >>= fun () -> C.listen ~connection ~callback ()
  >>= fun () -> C.send_quit ~connection

let _ = Lwt_main.run lwt_main

(* ocamlfind ocamlopt -package irc-client.lwt -linkpkg code.ml *)
