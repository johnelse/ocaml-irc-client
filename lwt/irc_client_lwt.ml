module Io = struct
  type 'a t = 'a Lwt.t
  let (>>=) = Lwt.bind
  let return = Lwt.return

  type file_descr = Lwt_unix.file_descr

  let open_socket server port =
    let sock = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
    let addr = Lwt_unix.ADDR_INET (Unix.inet_addr_of_string server, port) in
    lwt () = Lwt_unix.connect sock addr in
    return sock

  let close_socket = Lwt_unix.close

  let read = Lwt_unix.read
  let write = Lwt_unix.write

  let gethostbyname name =
    try_lwt
      lwt entry = Lwt_unix.gethostbyname name in
      let l = Array.to_list entry.Unix.h_addr_list in
      let l = List.map Unix.string_of_inet_addr l in
      Lwt.return l
    with Not_found ->
      Lwt.return_nil

  let iter = Lwt_list.iter_s
end

module Client = Irc_client.Make(Io)
