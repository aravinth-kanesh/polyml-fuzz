(* Include directive and signature extension *)

signature BASE =
sig
  type t
  val create : unit -> t
  val toString : t -> string
end;

signature EXTENDED =
sig
  include BASE
  val duplicate : t -> t
  val compare : t * t -> order
end;

structure IntBase : BASE =
struct
  type t = int
  fun create () = 0
  fun toString n = Int.toString n
end;

structure IntExtended : EXTENDED =
struct
  type t = int
  fun create () = 0
  fun toString n = Int.toString n
  fun duplicate n = n
  fun compare (x, y) =
    if x < y then LESS
    else if x > y then GREATER
    else EQUAL
end;

(* Multiple includes *)
signature SHOWABLE =
sig
  type t
  val show : t -> string
end;

signature COMPARABLE =
sig
  type t
  val compare : t * t -> order
end;

signature FULL =
sig
  include SHOWABLE
  include COMPARABLE
  sharing type SHOWABLE.t = COMPARABLE.t
  val default : t
end;

structure IntFull : FULL =
struct
  type t = int
  fun show n = Int.toString n
  fun compare (x, y) =
    if x < y then LESS
    else if x > y then GREATER
    else EQUAL
  val default = 0
end;
