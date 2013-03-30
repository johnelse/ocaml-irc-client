module type IO = sig
  type 'a t
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t

  type socket_domain
  type socket_type
  type sockaddr
  type file_descr

  val socket : socket_domain -> socket_type -> int -> file_descr
  val connect : file_descr -> sockaddr -> unit t

  val buffered_read : file_descr -> string -> int -> int -> unit t
  val buffered_write : file_descr -> string -> int -> int -> unit t
end
