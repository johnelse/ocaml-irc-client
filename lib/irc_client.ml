module Make(Io: Irc_transport.IO) = struct
  type connection_t = {
    sock: Io.file_descr;
  }

  open Io

  let rec really_write ~connection ~data ~offset ~length =
    if length = 0 then return () else
      Io.write connection.sock data offset length
      >>= (fun chars_written ->
        really_write ~connection ~data
          ~offset:(offset + chars_written)
          ~length:(length - chars_written))

  let send_raw ~connection ~data =
    let formatted_data = Printf.sprintf "%s\r\n" data in
    let length = String.length formatted_data in
    really_write ~connection ~data:formatted_data ~offset:0 ~length

  let send_join ~connection ~channel =
    send_raw ~connection ~data:(Printf.sprintf "JOIN %s" channel)

  let send_nick ~connection ~nick =
    send_raw ~connection ~data:(Printf.sprintf "NICK %s" nick)

  let send_pass ~connection ~password =
    send_raw ~connection ~data:(Printf.sprintf "PASS %s" password)

  let send_pong ~connection ~message =
    send_raw ~connection ~data:(Printf.sprintf "PONG %s" message)

  let send_privmsg ~connection ~target ~message =
    send_raw ~connection ~data:(Printf.sprintf "PRIVMSG %s %s" target message)

  let send_quit ~connection =
    send_raw ~connection ~data:"QUIT"

  let send_user ~connection ~username ~mode ~realname =
    send_raw ~connection
      ~data:(Printf.sprintf "USER %s %i * :%s" username mode realname)

  let connect ~server ~port ~username ~mode ~realname ~nick ~password =
    Io.open_socket server port >>= (fun sock ->
      let connection = {sock = sock} in
      send_pass ~connection ~password
      >>= (fun () -> send_nick ~connection ~nick)
      >>= (fun () -> send_user ~connection ~username ~mode ~realname)
      >>= (fun () -> return connection))
end
