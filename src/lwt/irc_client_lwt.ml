module Io_lwt = struct
  type 'a t = 'a Lwt.t
  let (>>=) = Lwt.bind
  let return = Lwt.return

  type file_descr = Lwt_unix.file_descr
  type inet_addr = Lwt_unix.inet_addr
  type config = unit

  let open_socket ?(config=()) addr port =
    let sock = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
    let sockaddr = Lwt_unix.ADDR_INET (addr, port) in
    Lwt_unix.connect sock sockaddr >>= fun () ->
    return sock

  let close_socket = Lwt_unix.close

  let read = Lwt_unix.read
  let write = Lwt_unix.write

  let read_with_timeout ~timeout fd buf off len =
    let open Lwt.Infix in
    Lwt.pick
      [ (read fd buf off len >|= fun i -> Some i);
        (Lwt_unix.sleep (float timeout) >|= fun () -> None);
      ]

  let gethostbyname name =
    Lwt.catch
      (fun () ->
      Lwt_unix.gethostbyname name >>= fun entry ->
      let addrs = Array.to_list entry.Unix.h_addr_list in
      Lwt.return addrs
    ) (function
      | Not_found -> Lwt.return_nil
      | e -> Lwt.fail e
      )

  let iter = Lwt_list.iter_s
  let sleep d = Lwt_unix.sleep (float d)
  let catch = Lwt.catch
  let time = Unix.time

  let pick = Some Lwt.pick
end

include Irc_client.Make(Io_lwt)
