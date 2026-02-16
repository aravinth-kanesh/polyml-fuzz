(* Signatures and signature matching *)

signature ORDERED =
sig
  type t
  val compare : t * t -> order
  val eq : t * t -> bool
  val lt : t * t -> bool
  val gt : t * t -> bool
end;

structure IntOrdered : ORDERED =
struct
  type t = int
  fun compare (x, y) =
    if x < y then LESS
    else if x > y then GREATER
    else EQUAL
  fun eq (x, y) = x = y
  fun lt (x, y) = x < y
  fun gt (x, y) = x > y
end;

signature STACK =
sig
  type 'a stack
  val empty : 'a stack
  val push : 'a * 'a stack -> 'a stack
  val pop : 'a stack -> ('a * 'a stack) option
  val isEmpty : 'a stack -> bool
end;

structure ListStack : STACK =
struct
  type 'a stack = 'a list
  val empty = []
  fun push (x, xs) = x :: xs
  fun pop [] = NONE
    | pop (x :: xs) = SOME (x, xs)
  fun isEmpty [] = true
    | isEmpty _ = false
end;

val s1 = ListStack.push (1, ListStack.empty);
val s2 = ListStack.push (2, s1);
val result = ListStack.pop s2;
