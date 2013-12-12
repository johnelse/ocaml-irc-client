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

  let iter = Lwt_list.iter_s
end

module Client = struct
  include Irc_client.Make(Io)

  let connect_by_name ~server ~port ?(username="")
  ?(mode=0) ?(realname="") ~nick ?(password="") () =
    try
      lwt addr = Lwt_unix.gethostbyname server in
      if Array.length addr.Unix.h_addr_list = 0
        then Lwt.return_none
        else
          let ip = addr.Unix.h_addr_list.(0) in
          let server = Unix.string_of_inet_addr ip in
          let c = connect ~server ~port ~username ~mode ~realname ~nick ~password in
          Lwt.return (Some c)
    with Not_found ->
      Lwt.return_none
end
