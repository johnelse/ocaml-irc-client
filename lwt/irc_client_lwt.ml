module Io : Irc_transport.IO = struct
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
