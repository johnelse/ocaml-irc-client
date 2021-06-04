module type IO = sig
  type 'a t
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  val (>|=) : 'a t -> ('a -> 'b) -> 'b t
  val return : 'a -> 'a t

  type file_descr

  type inet_addr

  type config

  val open_socket : ?config:config -> inet_addr -> int -> file_descr t
  val close_socket : file_descr -> unit t

  val read : file_descr -> Bytes.t -> int -> int -> int t
  val write : file_descr -> Bytes.t -> int -> int -> int t

  val read_with_timeout : timeout:int -> file_descr -> Bytes.t -> int -> int -> int option t

  val gethostbyname : string -> inet_addr list t

  val iter : ('a -> unit t) -> 'a list -> unit t
  val catch : (unit -> 'a t) -> (exn -> 'a t) -> 'a t

  val sleep : int -> unit t
  val time : unit -> float
  val pick : ('a t list -> 'a t) option
end
