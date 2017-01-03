open Lwt.Infix

module Io = struct
  type 'a t = 'a Lwt.t
  let (>>=) = Lwt.bind
  let return = Lwt.return

  type file_descr = {
    ic: Tls_lwt.ic;
    oc: Tls_lwt.oc;
  }

  type inet_addr = string

  let default_config : Tls.Config.client =
    Tls.Config.client ~authenticator:X509.Authenticator.null ()

  let config : Tls.Config.client ref = ref default_config

  let open_socket addr port : file_descr t =
    Tls_lwt.connect_ext !config (addr,port) >|= fun (ic,oc) ->
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

  let pick = Some Lwt.pick
end

include Irc_client.Make(Io)
