module Io(Params: sig
    val check_certificate: bool
    val ssl_protocol: Ssl.protocol
  end) = struct
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
    let ctx = Ssl.create_context Params.ssl_protocol Ssl.Client_context in
    if Params.check_certificate then
      begin
        Ssl.set_verify ctx [Ssl.Verify_peer] (Some Ssl.client_verify_callback);
        Ssl.set_verify_depth ctx 3
      end;
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

module Make(Params: sig
    val check_certificate: bool
    val ssl_protocol: Ssl.protocol
  end) = struct
  module Io = Io(Params)
  include Irc_client.Make(Io)
end
