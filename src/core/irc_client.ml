module Log = Irc_helpers.Log

module type CLIENT = sig
  module Io : sig
    type 'a t
    type inet_addr
    type config
  end

  type connection_t

  val send : connection:connection_t -> Irc_message.t -> unit Io.t
  (** Send the given message *)

  val send_join : connection:connection_t -> channel:string -> unit Io.t
  (** Send the JOIN command. *)

  val send_nick : connection:connection_t -> nick:string -> unit Io.t
  (** Send the NICK command. *)

  val send_pass : connection:connection_t -> password:string -> unit Io.t
  (** Send the PASS command. *)

  val send_pong : connection:connection_t ->
    message1:string -> message2:string -> unit Io.t
  (** Send the PONG command. *)

  val send_privmsg : connection:connection_t ->
    target:string -> message:string -> unit Io.t
  (** Send the PRIVMSG command. *)

  val send_notice : connection:connection_t ->
    target:string -> message:string -> unit Io.t
  (** Send the NOTICE command. *)

  val send_quit : ?msg:string -> connection:connection_t -> unit -> unit Io.t
  (** Send the QUIT command. *)

  val send_user : connection:connection_t ->
    username:string -> mode:int -> realname:string -> unit Io.t
  (** Send the USER command. *)

  val connect :
    ?username:string -> ?mode:int -> ?realname:string -> ?password:string ->
    ?sasl:bool -> ?config:Io.config ->
    addr:Io.inet_addr -> port:int -> nick:string -> unit ->
    connection_t Io.t
  (** Connect to an IRC server at address [addr]. The PASS command will be
      sent if [password] is not None. *)

  val connect_by_name :
    ?username:string -> ?mode:int -> ?realname:string -> ?password:string ->
    ?sasl:bool -> ?config:Io.config ->
    server:string -> port:int -> nick:string -> unit ->
    connection_t option Io.t
  (** Try to resolve the [server] name using DNS, otherwise behaves like
      {!connect}. Returns [None] if no IP could be found for the given
      name. See {!connect} for more details. *)

  (** Information on keeping the connection alive *)
  type keepalive = {
    mode: [`Active | `Passive];
    timeout: int;
  }

  val default_keepalive : keepalive
  (** Default value for keepalive: active mode with auto-reconnect *)

  val listen :
    ?keepalive:keepalive ->
    connection:connection_t ->
    callback:(
      connection_t ->
      Irc_message.parse_result ->
      unit Io.t) ->
    unit ->
    unit Io.t
  (** [listen connection callback] listens for incoming messages on
      [connection]. All server pings are handled internally; all other
      messages are passed, along with [connection], to [callback].
      @param keepalive the behavior on disconnection (if the transport
        supports {!Irc_transport.IO.pick} and {!Irc_transport.IO.sleep}) *)

  val reconnect_loop :
    ?keepalive:keepalive ->
    ?reconnect:bool ->
    after:int ->
    connect:(unit -> connection_t option Io.t) ->
    f:(connection_t -> unit Io.t) ->
    callback:(
      connection_t ->
      Irc_message.parse_result ->
      unit Io.t) ->
    unit ->
    unit Io.t
  (** A combination of {!connect} and {!listen} that, every time
      the connection is terminated, tries to start a new one
      after [after] seconds.
      @param after time before trying to reconnect
      @param connect how to reconnect
        (a closure over {!connect} or {!connect_by_name})
      @param callback the callback for {!listen}
      @param f the function to call after connection *)
end

module Make(Io: Irc_transport.IO) = struct
  module Io = Io

  type connection_t = {
    sock: Io.file_descr;
    buffer: Buffer.t;
    read_length: int;
    read_data: Bytes.t; (* for reading *)
    lines: string Queue.t; (* lines read so far *)
    mutable terminated: bool;
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
    Log.debug (fun k->k"send: %s" data);
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

  let send_auth_sasl ~connection ~user ~password =
    Log.debug (fun k->k"login using SASL with user=%S" user);
    send_raw ~connection ~data:"CAP REQ :sasl" >>= fun () ->
    send_raw ~connection ~data:"AUTHENTICATE PLAIN" >>= fun () ->
    let b64_login =
      Base64.encode_string @@
      Printf.sprintf "%s\x00%s\x00%s" user user password
    in
    let data = Printf.sprintf "AUTHENTICATE %s" b64_login in
    send_raw ~connection ~data

  let send_pass ~connection ~password =
    send ~connection (M.pass password)

  let send_ping ~connection ~message1 ~message2 =
    send ~connection (M.ping ~message1 ~message2)

  let send_pong ~connection ~message1 ~message2 =
    send ~connection (M.pong ~message1 ~message2)

  let send_privmsg ~connection ~target ~message =
    send ~connection (M.privmsg ~target message)

  let send_notice ~connection ~target ~message =
    send ~connection (M.notice ~target message)

  let send_quit ?(msg="") ~connection () =
    send ~connection (M.quit ~msg)

  let send_user ~connection ~username ~mode ~realname =
    let msg = M.user ~username ~mode ~realname in
    send ~connection msg

  let mk_connection_ sock =
    let read_length = 1024 in
    {
      sock = sock;
      buffer = Buffer.create 128;
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
    else begin
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
    end

  type nick_retry = {
      mutable nick: string;
      mutable tries: int;
  }

  let welcome_timeout = 30.
  let max_nick_retries = 3

  let wait_for_welcome ~start ~connection ~nick =
    let nick_try = {
        nick = nick;
        tries = 1
    } in
    let rec aux () =
      let now = Io.time () in
      let timeout = start +. welcome_timeout -. now in
      if timeout < 0.5 then return ()
      else begin
        if nick_try.tries > max_nick_retries then return ()
        else begin
          (* wait a bit more *)
          let timeout = int_of_float (ceil timeout) in
          assert (timeout > 0);
          (* logf "wait for welcome message (%ds)" timeout >>= fun () -> *)
          next_line_ ~timeout ~connection
          >>= function
          | Timeout
          | End -> return ()
          | Read line ->
            Log.debug (fun k->k"read: %s" line);
            begin match M.parse line with
              | Result.Ok {M.command = M.Other ("001", _); _} ->
                (* we received "RPL_WELCOME", i.e. 001 *)
                return ()
              | Result.Ok {M.command = M.PING (message1, message2); _} ->
                (* server may ask for ping at any time *)
                send_pong ~connection ~message1 ~message2 >>= aux
              | Result.Ok {M.command = M.Other ("433", _); _} ->
                (* we received "ERR_NICKNAMEINUSE" *)
                nick_try.nick <- nick_try.nick ^ "_";
                nick_try.tries <- nick_try.tries + 1;
                Log.err (fun k->k"Nick name already in use, tying %s" nick_try.nick);
                send_nick ~connection ~nick:nick_try.nick >>= aux
              | _ -> aux ()
            end
        end
      end
    in
    aux () >|= fun () ->
    Log.info (fun k->k"finished waiting for welcome msg")

  let connect
      ?username ?(mode=0) ?(realname="irc-client")
      ?password ?(sasl=true) ?config ~addr ~port ~nick () =
    Io.open_socket ?config addr port >>= (fun sock ->
      let connection = mk_connection_ sock in

      let cap_end = ref false in
      begin
        match username, password with
        | Some user, Some password when sasl ->
          cap_end := true;
          send_auth_sasl ~connection ~user ~password
        | _, Some password -> send_pass ~connection ~password
        | _ -> return ()
      end
      >>= fun () ->
      let username = match username with Some u -> u | None -> "ocaml-irc-client" in
      send_nick ~connection ~nick
      >>= fun () -> send_user ~connection ~username ~mode ~realname
      >>= fun () ->
      begin
        if !cap_end then send_raw ~connection ~data:"CAP END" else return()
      end
      >>= fun () -> wait_for_welcome ~start:(Io.time ()) ~connection ~nick
      >>= fun () -> return connection)

  let connect_by_name
      ?(username="irc-client") ?(mode=0) ?(realname="irc-client")
      ?password ?sasl ?config ~server ~port ~nick () =
    Io.gethostbyname server
    >>= (function
      | [] -> Io.return None
      | addr :: _ ->
        connect ~addr ~port ~username ~mode ~realname ~nick ?password ?sasl ?config ()
        >>= fun connection -> Io.return (Some connection))

  (** Information on keeping the connection alive *)
  type keepalive = {
    mode: [`Active | `Passive];
    timeout: int;
  }

  let default_keepalive: keepalive = {
    mode = `Active;
    timeout = 60;
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
      let now = Io.time () in
      let time_til_ping =
        (max state.last_active_ping state.last_seen)
        +. (float keepalive.timeout /. 2.) -. now
      in
      if state.finished
      then Io.return ()
      else begin
        (* send "ping" if active mode and it's been long enough *)
        if time_til_ping < 0. then (
          state.last_active_ping <- now;
          Log.debug (fun k->k"send ping to server...");
          (* try to send a ping, but ignore errors *)
          Io.catch
            (fun () -> send_ping ~connection ~message1:"ping" ~message2:"")
            (fun _ -> Io.return ())
        ) else (
          Io.return ()
        )
          >>= fun () ->
          (* sleep until the due date, then check again *)
          Io.sleep (int_of_float time_til_ping + 1)
      end
      >>= fun () -> loop ()
    in
    loop ()

  let listen ?(keepalive=default_keepalive) ~connection ~callback () =
    (* main loop *)
    let rec listen_rec state =
      let now = Io.time () in
      let timeout = state.last_seen +. float keepalive.timeout -. now in
      next_line_ ~timeout:(int_of_float (ceil timeout)) ~connection
      >>= function
      | Timeout ->
        state.finished <- true;
        Log.info (fun k->k"client timeout");
        Io.return ()
      | End ->
        state.finished <- true;
        Log.info (fun k->k"connection closed");
        Io.return ()
      | Read line ->
        (* update "last_seen" field *)
        Log.debug (fun k->k"read: %s" line);
        let now = Io.time() in
        state.last_seen <- max now state.last_seen;
        begin match M.parse line with
          | Result.Ok {M.command = M.PING (message1, message2); _} ->
            (* Handle pings without calling the callback. *)
            Log.debug (fun k->k"reply pong to server");
            send_pong ~connection ~message1 ~message2
          | Result.Ok {M.command = M.PONG _; _} ->
            (* active response from server *)
            Io.return ()
          | result -> callback connection result
        end
        >>= fun () ->
        if state.finished
        then Io.return ()
        else listen_rec state
    in
    let state = {
      last_seen = Io.time();
      last_active_ping = Io.time();
      finished = false;
    } in
    (* connect, serve, etc. *)
    begin match Io.pick with
      | Some pick when keepalive.mode = `Active ->
        pick [
          listen_rec state;
          active_ping_thread keepalive state ~connection;
        ]
      | _ ->
        listen_rec state
    end

  let reconnect_loop ?keepalive ?(reconnect=true) ~after ~connect ~f ~callback () =
    let rec aux () =
      Io.catch
        (fun () ->
           connect () >>= function
           | None -> Log.info (fun k->k"could not connect"); return true
           | Some connection ->
             f connection >>= fun () ->
             listen ?keepalive ~connection ~callback () >>= fun () ->
             Log.info (fun k->k"connection terminated.");
             return reconnect)
        (fun e ->
           Log.err (fun k->k"reconnect_loop: exception %s" (Printexc.to_string e));
           return true)
      >>= fun loop ->
      (* wait and reconnect *)
      Io.sleep after >>= fun () ->
      if loop then (
        Log.info (fun k->k"try to reconnect...");
        aux()
      ) else return ()
    in
    aux ()
end
