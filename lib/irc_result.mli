(** Handling of results from operations which may fail. *)

type ('ok, 'err) t = [
  | `Ok of 'ok
  | `Error of 'err
]
