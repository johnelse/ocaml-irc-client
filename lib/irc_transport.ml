module type IO = sig
  type 'a t
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t

  type file_descr

  val open_socket : string -> int -> file_descr t
  val close_socket : file_descr -> unit t

  val buffered_read : file_descr -> string -> int -> int -> unit t
  val buffered_write : file_descr -> string -> int -> int -> unit t
end
