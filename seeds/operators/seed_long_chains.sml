(* Long operator chains to stress parser *)

infixl 6 +++;
infixl 7 ***;
infixr 5 :::;
infix 4 @@;

fun a +++ b = a + b;
fun a *** b = a * b;
fun a ::: b = a :: b;
fun f @@ x = f x;

(* Very long chain of same operator *)
val r1 = 1 +++ 2 +++ 3 +++ 4 +++ 5 +++ 6 +++ 7 +++ 8 +++ 9 +++ 10
         +++ 11 +++ 12 +++ 13 +++ 14 +++ 15 +++ 16 +++ 17 +++ 18
         +++ 19 +++ 20;

val r2 = 2 *** 3 *** 4 *** 5 *** 6 *** 7 *** 8 *** 9 *** 10;

(* Long chain of mixed operators *)
val r3 = 1 +++ 2 *** 3 +++ 4 *** 5 +++ 6 *** 7 +++ 8 *** 9 +++ 10;

(* Right-associative chain *)
val r4 = 1 ::: 2 ::: 3 ::: 4 ::: 5 ::: 6 ::: 7 ::: 8 ::: 9 ::: 10 ::: [];

(* Nested parenthesized expressions *)
val r5 = ((((1 +++ 2) *** 3) +++ 4) *** 5) +++ 6;

val r6 = 1 +++ (2 *** (3 +++ (4 *** (5 +++ 6))));

(* Function application chains *)
val r7 = (fn x => x + 1) @@ (fn y => y * 2) @@ (fn z => z - 1) @@ 10;

(* Mix of operators and function applications *)
fun f x = x * 2;
fun g x = x + 3;

val r8 = f (g (1 +++ 2 *** 3));
val r9 = 1 +++ f (2 *** g 3);

(* Deeply nested with multiple precedence levels *)
val r10 = 1 +++ 2 *** 3 +++ 4 *** (5 +++ 6 *** (7 +++ 8 *** (9 +++ 10)));
