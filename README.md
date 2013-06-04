IRC client library, supporting Lwt and Unix blocking IO.

Build dependencies
------------------

* [lwt](http://ocsigen.org/lwt/)
* [obuild](https://github.com/vincenthz/obuild)
* [oUnit](http://ounit.forge.ocamlcore.org/)

The latest tagged version is available via [opam](http://opam.ocamlpro.com): `opam install irc-client`

Usage
-----

Simple bot which connects to a channel, sends a message, and then logs all
messages in that channel to stdout:

```ocaml
open Irc_client_lwt.Io
module C = Irc_client_lwt.Client

let string_opt_to_string = function
  | None -> "None"
  | Some s -> Printf.sprintf "Some %s" s

let string_list_to_string string_list =
  Printf.sprintf "[%s]" (String.concat "; " string_list)

let callback input =
  let open Irc_message in
  match input with
  | Message {prefix=prefix; command=command; params=params; trail=trail} ->
    Lwt_io.printf "Got message: prefix=%s; command=%s; params=%s; trail=%s\n"
      (string_opt_to_string prefix)
      command
      (string_list_to_string params)
      (string_opt_to_string trail)
  | Parse_error (raw, error) ->
    Lwt_io.printf "Failed to parse \"%s\" because: %s" raw error

let lwt_main =
  C.connect ~server:"1.2.3.4" ~port:6667 ~username:"demo_irc_bot"
    ~mode:0 ~realname:"Demo IRC bot" ~nick:"demo_irc_bot" ~password:"foo"
  >>= (fun connection ->
    Lwt_io.printl "Connected"
    >>= (fun () -> C.send_join ~connection ~channel:"#mychannel")
    >>= (fun () -> C.send_privmsg ~connection ~target:"#mychannel"  ~message:"hi")
    >>= (fun () -> C.listen ~connection ~callback)
    >>= (fun () -> C.send_quit ~connection))

let _ = Lwt_main.run lwt_main
```
