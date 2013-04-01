module Io : Irc_transport.IO = struct
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

  let rec buffered_read fd str offset length =
    if length = 0 then () else
      let chars_read = Unix.read fd str offset length in
      if chars_read = 0
      then raise End_of_file
      else buffered_read fd str (offset + chars_read) (length - chars_read)

  let rec buffered_write fd str offset length =
    if length = 0 then () else
      let chars_written = Unix.write fd str offset length in
      buffered_write fd str (offset + chars_written) (length - chars_written)
end

module Client = Irc_client.Make(Io)
