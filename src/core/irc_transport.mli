(** Type of IO modules which can be used to create an IRC client library, via
    the {{:Irc_client.Make.html}Irc_client.Make} functor. *)

module type IO = sig
  type 'a t
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t

  type file_descr
  (** A connection to the remote IRC server *)

  type inet_addr
  (** Remote addresses *)

  type config
  (** Additional configuration, on a per-connection basis. *)

  val open_socket : ?config:config -> inet_addr -> int -> file_descr t
  val close_socket : file_descr -> unit t

  val read : file_descr -> Bytes.t -> int -> int -> int t
  val write : file_descr -> Bytes.t -> int -> int -> int t

  val read_with_timeout : timeout:int -> file_descr -> Bytes.t -> int -> int -> int option t
  (** [read_with_timeout ~timeout fd buf off len] returns [Some n] if it
      could read [n] bytes into [buf] (slice [off,...,off+len-1]),
      or [None] if nothing was read before [timeout] seconds. *)

  val gethostbyname : string -> inet_addr list t
  (** List of IPs that correspond to the given hostname (or an empty
      list if none is found) *)

  val iter : ('a -> unit t) -> 'a list -> unit t

  val catch : (unit -> 'a t) -> (exn -> 'a t) -> 'a t
  (** Catch asynchronous exception
      @since NEXT_RELEASE *)

  val sleep : int -> unit t
  (* [sleep t] sleeps for [t] seconds, then returns. *)

  val time : unit -> float
  (** Current wall time (used for timeouts). Typically, {!Unix.time}.
      @since NEXT_RELEASE *)

  val pick : ('a t list -> 'a t) option
  (** OPTIONAL
      [pick l] returns the first  thread of [l] that terminates (and might
      cancel the others) *)
end
