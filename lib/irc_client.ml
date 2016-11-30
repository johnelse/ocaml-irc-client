module Make(Io: Irc_transport.IO) = struct
  type connection_params = {
    username: string;
    mode: int;
    realname: string;
    password: string option;
    addr: Io.inet_addr;
    port: int;
    nick: string;
  }

  type connection_t = {
    sock: Io.file_descr;
    buffer: Buffer.t;
    read_length: int;
    read_data: Bytes.t; (* for reading *)
    lines: string Queue.t; (* lines read so far *)
    params: connection_params;
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

  let mk_connection_ sock params =
    let read_length = 1024 in
    { sock = sock;
      buffer=Buffer.create 128;
      read_length;
      read_data = Bytes.make read_length ' ';
      lines = Queue.create ();
      params;
      terminated = false;
    }

  let rec next_line_ ~connection:c : string option Io.t =
    if c.terminated
    then return None
    else if Queue.length c.lines > 0
    then return (Some (Queue.pop c.lines))
    else (
      (* Read some data into our string. *)
      Io.read c.sock c.read_data 0 c.read_length
      >>= function
      | 0 ->
        c.terminated <- true;
        return None (* EOF from server - we have quit or been kicked. *)
      | len ->
        (* read some data, push lines into [c.lines] (if any) *)
        let input = Bytes.sub_string c.read_data 0 len in
        let lines = Irc_helpers.handle_input ~buffer:c.buffer ~input in
        List.iter (fun l -> Queue.push l c.lines) lines;
        next_line_ ~connection:c
    )

  let rec wait_for_welcome ~connection =
    next_line_ ~connection
    >>= function
    | None -> return ()
    | Some line ->
      match M.parse line with
        | Result.Ok {M.command = M.Other ("001", _); _} ->
          (* we received "RPL_WELCOME", i.e. 001 *)
          return ()
        | Result.Ok {M.command = M.PING message; _} ->
          (* server may ask for ping at any time *)
          send_pong ~connection ~message >>= fun () -> wait_for_welcome ~connection
        | _ -> wait_for_welcome ~connection

  let mk_params ~username ~mode ~realname ~password ~addr ~port ~nick ()
    : connection_params
    = {
      username; mode; realname; password; addr; port; nick;
    }

  let connect_params (p:connection_params) : connection_t Io.t =
    Io.open_socket p.addr p.port >>= (fun sock ->
      let connection = mk_connection_ sock p in
      begin
        match p.password with
        | Some password -> send_pass ~connection ~password
        | None -> return ()
      end
      >>= fun () -> send_nick ~connection ~nick:p.nick
      >>= fun () ->
        send_user ~connection ~username:p.username ~mode:p.mode ~realname:p.realname
      >>= fun () -> wait_for_welcome ~connection
      >>= fun () -> return connection)

  let connect
      ?(username="irc-client") ?(mode=0) ?(realname="irc-client")
      ?password ~addr ~port ~nick () =
    let params =
      mk_params ~username ~mode ~realname ~password ~addr ~port ~nick ()
    in
    connect_params params

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
    reconnect_delay: int option;
    (* [Some t] means reconnect automatically after [t] seconds *)
  }

  let default_keepalive: keepalive = {
    mode=`Active;
    timeout=60;
    reconnect_delay = Some 30;
  }

  type listen_keepalive_state = {
    mutable last_seen: float;
    mutable last_active_ping: float;
    mutable finish: bool;
  }

  let listen ?(keepalive=default_keepalive) ~connection ~callback =
    (* main loop *)
    let rec listen_rec state =
      next_line_ ~connection
      >>= function
      | None -> return ()
      | Some line ->
        begin match M.parse line with
          | Result.Ok {M.command = M.PING message; _} ->
            (* update "last_seen" field *)
            let now = Sys.time() in
            state.last_seen <- max now state.last_seen;
            (* Handle pings without calling the callback. *)
            log "reply pong to server" >>= fun () ->
            send_pong ~connection ~message
          | result -> callback connection result
        end
        >>= fun () ->
        if state.finish
        then Io.return ()
        else listen_rec state

    (* main loop for timeout *)
    and timeout_thread sleep state =
      let now = Sys.time() in
      let time_til_timeout =
        state.last_seen +. float keepalive.timeout -. now
      and time_til_ping =
        state.last_active_ping +. float keepalive.timeout -. now
      in
      if time_til_timeout < 0. then (
        (* done *)
        log "client timeout" >>= fun () ->
        state.finish <- true;
        (* try to wake up the listening thread, so it can die *)
        really_write ~connection ~data:"\n" ~offset:0 ~length:1
      ) else (
        (* send "ping" if active mode and it's been long enough *)
        if keepalive.mode = `Active && time_til_ping < 0. then (
          state.last_active_ping <- now;
          log "send ping to server..." >>= fun () ->
          send_ping ~connection ~message:"ping"
        ) else (
          Io.return ()
        )
        >>= fun () ->
        (* sleep until the due date, then check again *)
        sleep (time_til_timeout +. 0.5) >>= fun () ->
        timeout_thread sleep state
      )
    in

    (* main loop: connect, wait for termination, and connect again
       if [keepalive.reconnect_delay = Some _]. *)
    let rec connect_loop connection =
      let state = {
        last_seen = Sys.time();
        last_active_ping = Sys.time();
        finish = false;
      } in
      (* connect, serve, etc. *)
      begin match Io.pick, Io.sleep with
        | Some pick, Some sleep ->
          pick
            [ listen_rec state;
              timeout_thread sleep state;
            ]
        | _ ->
          listen_rec state
      end
      (* terminated. Shall we reconnect? *)
      >>= fun () ->
      match Io.sleep, keepalive.reconnect_delay with
        | None, _
        | _, None -> Io.return () (* nope. *)
        | Some sleep, Some d ->
          (* yep. *)
          sleep (float d) >>= fun () ->
          log "try to reconnect..." >>= fun () ->
          connect_params connection.params >>= fun connection ->
          connect_loop connection
    in

    connect_loop connection
end
