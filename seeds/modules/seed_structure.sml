(* Simple structure and signature *)

signature COUNTER =
sig
  type t
  val zero : t
  val inc : t -> t
  val dec : t -> t
  val value : t -> int
end;

structure Counter :> COUNTER =
struct
  type t = int
  val zero = 0
  fun inc n = n + 1
  fun dec n = n - 1
  fun value n = n
end;

val c = Counter.zero;
val c1 = Counter.inc c;
val c2 = Counter.inc c1;
val v = Counter.value c2;
