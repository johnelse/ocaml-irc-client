open Lwt
module C = Irc_client_lwt_ssl
module M = Irc_message

let host = ref "irc.libera.chat"
let port = ref 6697
let nick = ref "bobobobot"
let channel = ref "#demo_irc"
let check_certif = ref false
let debug = ref false
let message = "Hello, world!  This is a test from ocaml-irc-client"

let callback connection result =
  match result with
  | Result.Ok ({M.command=M.Other _ ; _}as msg) ->
    Lwt_io.printf "Got unknown message: %s\n" (M.to_string msg)
    >>= fun () -> Lwt_io.flush Lwt_io.stdout
  | Result.Ok ({M.command=M.PRIVMSG (target, data); _} as msg) ->
    Lwt_io.printf "Got message: %s\n" (M.to_string msg)
    >>= fun () -> Lwt_io.flush Lwt_io.stdout
    >>= fun () -> C.send_privmsg ~connection ~target ~message:("ack: " ^ data)
  | Result.Ok msg ->
    Lwt_io.printf "Got message: %s\n" (M.to_string msg)
    >>= fun () -> Lwt_io.flush Lwt_io.stdout
  | Result.Error e ->
    Lwt_io.printl e

let lwt_main () =
  let config = C.Config.({default with check_certificate= !check_certif}) in
  let username, password, sasl =
    match Sys.getenv "USER", Sys.getenv "PASSWORD" with
    | u, p -> u, Some p, true
    | exception _ -> "ocaml-irc-client", None, false
  in
  C.reconnect_loop
    ~after:30
    ~connect:(fun () ->
      Lwt_io.printl "Connecting..." >>= fun () ->
      C.connect_by_name ~config ~username ?password ~sasl
        ~server:!host ~port:!port ~nick:!nick ()
    )
    ~f:(fun connection ->
      Lwt_io.printl "Connected" >>= fun () ->
      Lwt_io.printl "send join msg" >>= fun () ->
      C.send_join ~connection ~channel:!channel >>= fun () ->
      C.send_privmsg ~connection ~target:!channel ~message
    )
    ~callback
    ()

let options = Arg.align
  [ "-host", Arg.Set_string host, " set remove server host name"
  ; "-port", Arg.Set_int port, " set remote server port"
  ; "-chan", Arg.Set_string channel, " channel to join"
  ; "-nick", Arg.Set_string nick, " nickname"
  ; "-check", Arg.Set check_certif, " check certificate"
  ; "-no-check", Arg.Clear check_certif, " do not check certificate"
  ; "-debug", Arg.Set debug, " enable debug"
  ]

let () =
  Logs.set_reporter (Logs.format_reporter());
  Arg.parse options (fun _ -> ())
    "example.exe [options]\nif USER and PASSWORD env vars are set, uses SASL authentication";
  Logs.set_level ~all:true (Some (if !debug then Logs.Debug else Logs.Info));
  Lwt_main.run
    (Lwt.catch
       lwt_main
       (fun e ->
          Printf.printf "exception: %s\n" (Printexc.to_string e); exit 1))

(* ocamlfind ocamlopt -package irc-client.lwt -linkpkg code.ml *)

