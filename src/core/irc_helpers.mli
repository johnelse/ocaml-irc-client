(** Helper functions for buffering data as it is read from a socket. *)

val split : str:string -> c:char -> string list
(** Split a string [str] at each occurrence of the character [c]. *)

val split1_exn : str:string -> c:char -> string * string
(** Split a string [str] at the first occurrence of the character [c].
    @raise Not_found if the separator isn't found. *)

val handle_input : buffer:Buffer.t -> input:string -> string list
(** Given a [buffer] and a string [input], append the input to the buffer,
    return all whole lines present in the buffer, and reinitialise the buffer to
    contain only the substring which follows all the whole lines. *)

module Log : Logs.LOG
