module type IO = sig
  type 'a t
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t

  type file_descr

  val open_socket : string -> int -> file_descr t
  val close_socket : file_descr -> unit t

  val read : file_descr -> string -> int -> int -> int t
  val write : file_descr -> string -> int -> int -> int t

  val gethostbyname : string -> string list t
    (** List of IPs that correspond to the given hostname (or an empty
        list if none is found) *)

  val iter : ('a -> unit t) -> 'a list -> unit t
end
