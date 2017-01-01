module Make(Io: Irc_transport.IO) = struct
  type connection_t = {
    sock: Io.file_descr;
    buffer: Buffer.t;
    read_length: int;
    read_data: Bytes.t; (* for reading *)
    lines: string Queue.t; (* lines read so far *)
    mutable terminated: bool;
  }

  (* logging *)

  let log_ : (string -> unit Io.t) ref = ref (fun _ -> Io.return ())
  let set_log f = log_ := f

  let log s = !log_ (Printf.sprintf "[%.2f] %s" (Sys.time()) s)
  let logf s = Printf.ksprintf log s

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

  let send_ping ~connection ~message =
    send ~connection (M.ping message)

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

  let mk_connection_ sock =
    let read_length = 1024 in
    { sock = sock;
      buffer=Buffer.create 128;
      read_length;
      read_data = Bytes.make read_length ' ';
      lines = Queue.create ();
      terminated = false;
    }

  type 'a input_res =
    | Read of 'a
    | Timeout
    | End

  let rec next_line_ ~timeout ~connection:c : string input_res Io.t =
    if c.terminated
    then return End
    else if Queue.length c.lines > 0
    then return (Read (Queue.pop c.lines))
    else (
      (* Read some data into our string. *)
      Io.read_with_timeout ~timeout c.sock c.read_data 0 c.read_length
      >>= function
      | None -> return Timeout
      | Some 0 ->
        c.terminated <- true;
        return End (* EOF from server - we have quit or been kicked. *)
      | Some len ->
        (* read some data, push lines into [c.lines] (if any) *)
        let input = Bytes.sub_string c.read_data 0 len in
        let lines = Irc_helpers.handle_input ~buffer:c.buffer ~input in
        List.iter (fun l -> Queue.push l c.lines) lines;
        next_line_ ~timeout ~connection:c
    )

  let welcome_timeout = 30

  let rec wait_for_welcome ~timeout ~connection =
    next_line_ ~timeout ~connection
    >>= function
    | Timeout
    | End -> return ()
    | Read line ->
      match M.parse line with
        | Result.Ok {M.command = M.Other ("001", _); _} ->
          (* we received "RPL_WELCOME", i.e. 001 *)
          return ()
        | Result.Ok {M.command = M.PING message; _} ->
          (* server may ask for ping at any time *)
          send_pong ~connection ~message >>= fun () ->
          wait_for_welcome ~timeout ~connection
        | _ -> wait_for_welcome ~timeout:welcome_timeout ~connection

  let connect
      ?(username="irc-client") ?(mode=0) ?(realname="irc-client")
      ?password ?config ~addr ~port ~nick () =
    Io.open_socket ?config addr port >>= (fun sock ->
      let connection = mk_connection_ sock in
      begin
        match password with
        | Some password -> send_pass ~connection ~password
        | None -> return ()
      end
      >>= fun () -> send_nick ~connection ~nick
      >>= fun () -> send_user ~connection ~username ~mode ~realname
      >>= fun () -> wait_for_welcome ~timeout:welcome_timeout ~connection
      >>= fun () -> return connection)

  let connect_by_name
      ?(username="irc-client") ?(mode=0) ?(realname="irc-client")
      ?password ~server ~port ~nick () =
    Io.gethostbyname server
    >>= (function
      | [] -> Io.return None
      | addr :: _ ->
        connect ~addr ~port ~username ~mode ~realname ~nick ?password ()
        >>= fun connection -> Io.return (Some connection))

  (** Information on keeping the connection alive *)
  type keepalive = {
    mode: [`Active | `Passive];
    timeout: int;
  }

  let default_keepalive: keepalive = {
    mode=`Active;
    timeout=60;
  }

  type listen_keepalive_state = {
    mutable last_seen: float;
    mutable last_active_ping: float;
    mutable finished: bool;
  }

  (* main loop for pinging server actively *)
  let active_ping_thread keepalive state ~connection =
    let rec loop () =
      assert (keepalive.mode = `Active);
      let now = Sys.time() in
      let time_til_ping =
        state.last_active_ping +. float keepalive.timeout -. now
      in
      if state.finished then (
        Io.return ()
      ) else (
        (* send "ping" if active mode and it's been long enough *)
        if time_til_ping < 0. then (
          state.last_active_ping <- now;
          log "send ping to server..." >>= fun () ->
          send_ping ~connection ~message:"ping"
        ) else (
          Io.return ()
        )
          >>= fun () ->
          (* sleep until the due date, then check again *)
          Io.sleep (int_of_float time_til_ping + 1) >>= fun () ->
          loop ()
      )
    in
    loop ()

  let listen ?(keepalive=default_keepalive) ~connection ~callback () =
    (* main loop *)
    let rec listen_rec state =
      let now = Sys.time() in
      let timeout = state.last_seen +. float keepalive.timeout -. Sys.time () in
      next_line_ ~timeout:(int_of_float (ceil timeout)) ~connection
      >>= function
      | Timeout ->
        state.finished <- true;
        log "client timeout"
      | End ->
        state.finished <- true;
        log "connection closed"
      | Read line ->
        begin match M.parse line with
          | Result.Ok {M.command = M.PING message; _} ->
            (* update "last_seen" field *)
            state.last_seen <- max now state.last_seen;
            (* Handle pings without calling the callback. *)
            log "reply pong to server" >>= fun () ->
            send_pong ~connection ~message
          | Result.Ok {M.command = M.PONG _; _} ->
            (* active response from server, update "last_seen" field *)
            state.last_seen <- max now state.last_seen;
            Io.return ()
          | result -> callback connection result
        end
        >>= fun () ->
        if state.finished
        then Io.return ()
        else listen_rec state
    in
    let state = {
      last_seen = Sys.time();
      last_active_ping = Sys.time();
      finished = false;
    } in
    (* connect, serve, etc. *)
    begin match Io.pick with
      | Some pick when keepalive.mode = `Active ->
        pick
          [ listen_rec state;
            active_ping_thread keepalive state ~connection;
          ]
      | _ ->
        listen_rec state
    end

  let reconnect_loop ?keepalive ~after ~connect ~f ~callback () =
    let rec aux () =
      connect () >>= function
      | None -> log "could not connect" >>= aux
      | Some connection ->
        let t = listen ?keepalive ~connection ~callback () in
        f connection >>= fun () ->
        t >>= fun () ->
        log "connection terminated." >>= fun () ->
        Io.sleep after >>= fun () ->
        log "try to reconnect..." >>= fun () ->
        aux ()
    in
    aux ()
end
