
module Config = struct
  type t = {
    check_certificate: bool;
    proto: Ssl.protocol;
  }

  let default = { check_certificate=false; proto=Ssl.TLSv1_3; }
end

module Io_lwt_ssl = struct
  type 'a t = 'a Lwt.t
  let (>>=) = Lwt.bind
  let return = Lwt.return

  type file_descr = {
    ssl: Ssl.context;
    fd: Lwt_ssl.socket;
  }

  type config = Config.t
  type inet_addr = Lwt_unix.inet_addr

  let open_socket ?(config=Config.default) addr port : file_descr t =
    let ssl = Ssl.create_context config.Config.proto Ssl.Client_context in
    if config.Config.check_certificate then begin
      (* from https://github.com/johnelse/ocaml-irc-client/pull/21 *)
      Ssl.set_verify_depth ssl 3;
      Ssl.set_verify ssl [Ssl.Verify_peer] (Some Ssl.client_verify_callback);
    end;
    let sock = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
    let sockaddr = Lwt_unix.ADDR_INET (addr, port) in
    (* Printf.printf "connect socket…\n%!"; *)
    Lwt_unix.connect sock sockaddr >>= fun () ->
    (* Printf.printf "Ssl.connect socket…\n%!"; *)
    Lwt_ssl.ssl_connect sock ssl >>= fun sock ->
    Lwt.return {fd=sock; ssl}

  let close_socket {fd;ssl=_} =
    Lwt_ssl.close fd

  let read {fd;_} i len = Lwt_ssl.read fd i len
  let write {fd;_} s i len = Lwt_ssl.write fd s i len

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

include Irc_client.Make(Io_lwt_ssl)
