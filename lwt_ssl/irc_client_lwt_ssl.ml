module Io = struct
  type 'a t = 'a Lwt.t
  let (>>=) = Lwt.bind
  let return = Lwt.return

  type file_descr = Lwt_ssl.socket

  type inet_addr = Lwt_unix.inet_addr

  let _ =
    Ssl_threads.init ();
    Ssl.init ()

  let open_socket addr port =
    let sock = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
    let sockaddr = Lwt_unix.ADDR_INET (addr, port) in
    let ctx = Ssl.create_context Ssl.SSLv23 Ssl.Client_context in
    Lwt_unix.connect sock sockaddr >>= fun () ->
        Lwt_ssl.ssl_connect sock ctx

  let close_socket = Lwt_ssl.close

  let read = Lwt_ssl.read
  let write = Lwt_ssl.write

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
end

include Irc_client.Make(Io)
