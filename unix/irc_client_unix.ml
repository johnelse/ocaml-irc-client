module Io : Irc_transport.IO = struct
  type 'a t = 'a
  let (>>=) x f = f x
  let return x = x

  type socket_domain = Unix.socket_domain
  type socket_type = Unix.socket_type
  type sockaddr = Unix.sockaddr
  type file_descr = Unix.file_descr

  let socket = Unix.socket
  let connect = Unix.connect

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
