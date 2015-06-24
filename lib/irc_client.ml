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
    let formatted_data = Bytes.unsafe_of_string (Printf.sprintf "%s\r\n" data) in
    let length = Bytes.length formatted_data in
    really_write ~connection ~data:formatted_data ~offset:0 ~length

  module M = Irc_message

  let send ~connection msg =
    send_raw ~connection ~data:(M.to_string msg)

  let send_join ~connection ~channel =
    send ~connection (M.join ~chans:[channel] ~keys:None)

  let send_nick ~connection ~nick =
    send ~connection (M.nick nick)

  let send_pass ~connection ~password =
    send ~connection (M.pass password)

  let send_pong ~connection ~message =
    send ~connection (M.pong message)

  let send_privmsg ~connection ~target ~message =
    send ~connection (M.privmsg ~target message)

  let send_notice ~connection ~target ~message =
    send ~connection (M.notice ~target message)

  let send_quit ~connection =
    send ~connection (M.quit ~msg:None)

  let send_user ~connection ~username ~mode ~realname =
    let msg = M.user ~username ~mode ~realname in
    send ~connection msg

  let connect
      ?(username="irc-client") ?(mode=0) ?(realname="irc-client")
      ?password ~addr ~port ~nick () =
    Io.open_socket addr port >>= (fun sock ->
      let connection = {sock = sock} in begin
        match password with
        | Some password -> send_pass ~connection ~password
        | None -> return ()
      end
      >>= (fun () -> send_nick ~connection ~nick)
      >>= (fun () -> send_user ~connection ~username ~mode ~realname)
      >>= (fun () -> return connection))

  let connect_by_name
      ?(username="irc-client") ?(mode=0) ?(realname="irc-client")
      ?password ~server ~port ~nick () =
    Io.gethostbyname server
    >>= (function
      | [] -> Io.return None
      | addr :: _ ->
        connect ~addr ~port ~username ~mode ~realname ~nick ?password ()
        >>= (fun connection -> Io.return (Some connection)))

  let listen ~connection ~callback =
    let read_length = 1024 in
    let read_data = Bytes.make read_length ' ' in
    let rec listen' ~buffer =
      (* Read some data into our string. *)
      Io.read connection.sock read_data 0 read_length
      >>= function
      | 0 -> return () (* EOF from server - we have quit or been kicked. *)
      | len ->
        let input = Bytes.sub_string read_data 0 len in
        let lines = Irc_helpers.pop_lines ~buffer ~input in
        let _ = Io.iter
          (fun line ->
             match M.parse line with
             | `Ok {M.command = M.PING message; _} ->
               (* Handle pings without calling the callback. *)
               send_pong ~connection ~message
             | result ->
               callback connection result

          ) lines
        in
        listen' ~buffer
    in
    let buffer = Buffer.create 256 in
    listen' ~buffer
end
