(* Opaque signature ascription *)

signature COUNTER =
sig
  type counter
  val new : unit -> counter
  val increment : counter -> counter
  val value : counter -> int
end;

(* Transparent ascription - implementation visible *)
structure TransparentCounter : COUNTER =
struct
  type counter = int ref
  fun new () = ref 0
  fun increment c = (c := !c + 1; c)
  fun value c = !c
end;

(* Opaque ascription - implementation hidden *)
structure OpaqueCounter :> COUNTER =
struct
  type counter = int ref
  fun new () = ref 0
  fun increment c = (c := !c + 1; c)
  fun value c = !c
end;

val c1 = OpaqueCounter.new ();
val c2 = OpaqueCounter.increment c1;
val v = OpaqueCounter.value c2;

(* Abstract types *)
signature QUEUE =
sig
  type 'a queue
  val empty : 'a queue
  val enqueue : 'a * 'a queue -> 'a queue
  val dequeue : 'a queue -> ('a * 'a queue) option
end;

structure Queue :> QUEUE =
struct
  type 'a queue = 'a list * 'a list
  val empty = ([], [])

  fun enqueue (x, (front, back)) = (front, x :: back)

  fun dequeue ([], []) = NONE
    | dequeue (x :: front, back) = SOME (x, (front, back))
    | dequeue ([], back) = dequeue (rev back, [])
end;
