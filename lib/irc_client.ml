module Make(Io: Irc_transport.IO) = struct
  type connection_t = {
    sock: Io.file_descr;
  }

  let send_raw connection data =
    let formatted_data = Printf.sprintf "%s\r\n" data in
    let len = String.length formatted_data in
    Io.buffered_write connection.sock formatted_data 0 len

  let send_join connection channel =
    send_raw connection (Printf.sprintf "JOIN %s" channel)

  let send_nick connection nick =
    send_raw connection (Printf.sprintf "NICK %s" nick)

  let send_pass connection password =
    send_raw connection (Printf.sprintf "PASS %s" password)

  let send_pong connection message =
    send_raw connection (Printf.sprintf "PONG %s" message)

  let send_privmsg connection target message =
    send_raw connection (Printf.sprintf "PRIVMSG %s %s" target message)

  let send_quit connection =
    send_raw connection "QUIT"

  let send_user connection username mode realname =
    send_raw connection (Printf.sprintf "USER %s %i * :%s" username mode realname)
end
