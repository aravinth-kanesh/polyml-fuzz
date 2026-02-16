(* Custom infix operators *)

infix 7 ***;
infix 6 +++;
infix 5 @@;

fun a +++ b = a + b;
fun a *** b = a * b;
fun f @@ x = f x;

val result1 = 1 +++ 2 *** 3 +++ 4;
val result2 = (fn x => x * 2) @@ 21;

(* Operator precedence test *)
val x = 10 +++ 20 *** 30;  (* Should parse as: 10 + (20 * 30) = 610 *)
val y = 5 *** 10 +++ 3 *** 2;  (* (5 * 10) + (3 * 2) = 56 *)
