module Io = struct
  type 'a t = 'a
  let (>>=) x f = f x
  let return x = x

  type file_descr = Unix.file_descr

  let open_socket server port =
    let sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
    let addr = Unix.ADDR_INET (Unix.inet_addr_of_string server, port) in
    Unix.connect sock addr;
    sock

  let close_socket = Unix.close

  let read = Unix.read
  let write = Unix.write

  let iter = List.iter
end

module Client = struct
  include Irc_client.Make(Io)

  let connect_by_name ~server ~port ?(username="")
  ?(mode=0) ?(realname="") ~nick ?(password="") () =
    try
      let addr = Unix.gethostbyname server in
      if Array.length addr.Unix.h_addr_list = 0
        then None
        else
          let ip = addr.Unix.h_addr_list.(0) in
          let server = Unix.string_of_inet_addr ip in
          let c = connect ~server ~port ~username ~mode ~realname ~nick ~password in
          Some c
    with Not_found ->
      None
end
