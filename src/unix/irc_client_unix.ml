module Io_unix = struct
  type 'a t = 'a
  let (>>=) x f = f x
  let (>|=) x f = f x
  let return x = x

  type file_descr = Unix.file_descr
  type inet_addr = Unix.inet_addr
  type config = unit

  let open_socket ?config:(_=()) addr port =
    let sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
    let sockaddr = Unix.ADDR_INET (addr, port) in
    Unix.connect sock sockaddr;
    Unix.set_nonblock sock;
    sock

  let close_socket = Unix.close

  let read = Unix.read
  let write = Unix.write

  let read_with_timeout ~timeout fd buf off len =
    match Unix.select [fd] [] [] (float timeout) with
      | [fd], _, _ -> Some (Unix.read fd buf off len)
      | [], _, _ -> None
      | _ -> assert false

  let gethostbyname name =
    try
      let entry = Unix.gethostbyname name in
      Array.to_list entry.Unix.h_addr_list
    with Not_found ->
      []

  let iter = List.iter
  let sleep = Unix.sleep
  let catch f g = try f () with e -> g e
  let time = Unix.time

  let pick = None
end

include Irc_client.Make(Io_unix)

(* unix only allows passive mode *)
let default_keepalive = {mode=`Passive; timeout=300}

let listen ?(keepalive=default_keepalive) ~connection ~callback () =
  listen ~keepalive ~connection ~callback ()

let reconnect_loop ?(keepalive=default_keepalive) ?(reconnect=true) ~after ~connect ~f ~callback () =
  reconnect_loop ~keepalive ~reconnect ~after ~connect ~f ~callback ()
