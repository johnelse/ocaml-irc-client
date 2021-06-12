module Io_tls = struct
  type 'a t = 'a Lwt.t
  let (>>=) = Lwt.bind
  let (>|=) = Lwt.(>|=)
  let return = Lwt.return

  type file_descr = {
    ic: Tls_lwt.ic;
    oc: Tls_lwt.oc;
  }

  type inet_addr = string

  type config = Tls.Config.client

  let default_config : Tls.Config.client =
    Tls.Config.client ~authenticator:(fun ~host:_ _ -> Ok None) ()

  let open_socket ?(config=default_config) addr port : file_descr t =
    Tls_lwt.connect_ext config (addr,port) >|= fun (ic,oc) ->
    {ic; oc}

  let close_socket {ic;oc} =
    Lwt.join
      [ Lwt_io.close ic;
        Lwt_io.close oc;
      ]

  let read {ic;_} = Lwt_io.read_into ic
  let write {oc;_} = Lwt_io.write_from oc

  let read_with_timeout ~timeout (fd:file_descr) buf off len =
    let open Lwt.Infix in
    Lwt.pick
      [ (Lwt_io.read_into fd.ic buf off len >|= fun i -> Some i);
        (Lwt_unix.sleep (float timeout) >|= fun () -> None);
      ]

  let gethostbyname name = Lwt.return [name]

  let iter = Lwt_list.iter_s
  let sleep d = Lwt_unix.sleep (float d)
  let catch = Lwt.catch
  let time = Unix.time

  let pick = Some Lwt.pick
end

include Irc_client.Make(Io_tls)
