(** Type of IO modules which can be used to create an IRC client library, via
    the {{:Irc_client.Make.html}Irc_client.Make} functor. *)

module type IO = sig
  type 'a t
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t

  type file_descr

  type inet_addr

  val open_socket : inet_addr -> int -> file_descr t
  val close_socket : file_descr -> unit t

  val read : file_descr -> Bytes.t -> int -> int -> int t
  val write : file_descr -> string -> int -> int -> int t

  val gethostbyname : string -> inet_addr list t
  (** List of IPs that correspond to the given hostname (or an empty
      list if none is found) *)

  val iter : ('a -> unit t) -> 'a list -> unit t
end
