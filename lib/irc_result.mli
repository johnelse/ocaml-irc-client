(** Handling of results from operations which may fail. *)

type ('ok, 'err) t = [
  | `Ok of 'ok
  | `Error of 'err
]
(** A generic type representing the result of an operation which may fail. *)
