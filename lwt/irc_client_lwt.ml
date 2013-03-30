module Io : Irc_transport.IO = struct
  type 'a t = 'a Lwt.t
  let (>>=) = Lwt.bind
  let return = Lwt.return

  type socket_domain = Lwt_unix.socket_domain
  type socket_type = Lwt_unix.socket_type
  type sockaddr = Lwt_unix.sockaddr
  type file_descr = Lwt_unix.file_descr

  let socket = Lwt_unix.socket
  let connect = Lwt_unix.connect

  let rec buffered_read fd str offset length =
    if length = 0 then return () else
      lwt chars_read = Lwt_unix.read fd str offset length in
      if chars_read = 0
      then Lwt.fail End_of_file
      else buffered_read fd str (offset + chars_read) (length - chars_read)

  let rec buffered_write fd str offset length =
    if length = 0 then return () else
      lwt chars_written = Lwt_unix.write fd str offset length in
      buffered_write fd str (offset + chars_written) (length - chars_written)
end

module Client = Irc_client.Make(Io)
