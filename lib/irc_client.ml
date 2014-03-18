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

  let connect ~addr ~port ~username ~mode ~realname ~nick ?password () =
    Io.open_socket addr port >>= (fun sock ->
      let connection = {sock = sock} in begin
        match password with
        | Some password -> send_pass ~connection ~password
        | None -> return ()
      end
      >>= (fun () -> send_nick ~connection ~nick)
      >>= (fun () -> send_user ~connection ~username ~mode ~realname)
      >>= (fun () -> return connection))

  let connect_by_name ~server ~port ~username ~mode
      ~realname ~nick ?password () =
    Io.gethostbyname server
    >>= (fun addr_list ->
      match addr_list with
      | [] -> Io.return None
      | addr :: _ ->
        connect ~addr ~port ~username ~mode ~realname ~nick ?password ()
        >>= (fun connection -> Io.return (Some connection)))

  let listen ~connection ~callback =
    let read_length = 1024 in
    let read_data = String.create read_length in
    let rec listen' ~buffer =
      (* Read some data into our string. *)
      Io.read connection.sock read_data 0 read_length
      >>= (fun chars_read ->
        if chars_read = 0 (* EOF from server - we have quit or been kicked. *)
        then return ()
        else begin
          let input = String.sub read_data 0 chars_read in
          (* Update the buffer and extract the whole lines. *)
          let whole_lines = Irc_helpers.handle_input ~buffer ~input in
          (* Handle the whole lines which were read. *)
          Io.iter
            (fun line ->
              match Irc_message.parse line with
              | `Ok {Irc_message.command = "PING"; trail = Some trail} ->
                (* Handle pings without calling the callback. *)
                send_pong ~connection ~message:(":"^trail)
              | result ->
                callback ~connection ~result)
            whole_lines
        end)
      >>= (fun () -> listen' ~buffer)
    in
    let buffer = Buffer.create 0 in
    listen' ~buffer
end
