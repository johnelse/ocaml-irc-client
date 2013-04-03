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
end

module Client = Irc_client.Make(Io)
