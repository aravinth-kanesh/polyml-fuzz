(* Polymorphic datatypes and type variables *)

datatype 'a pair = Pair of 'a * 'a;

fun first (Pair (x, _)) = x;
fun second (Pair (_, y)) = y;
fun swap (Pair (x, y)) = Pair (y, x);

val int_pair = Pair (10, 20);
val string_pair = Pair ("hello", "world");

(* Nested polymorphism *)
datatype ('a, 'b) either = Left of 'a | Right of 'b;

fun map_either f g (Left x) = Left (f x)
  | map_either f g (Right y) = Right (g y);

val mixed1 = Left 42 : (int, string) either;
val mixed2 = Right "error" : (int, string) either;

(* Multiple type parameters *)
datatype ('a, 'b, 'c) triple = Triple of 'a * 'b * 'c;

fun get_first (Triple (x, _, _)) = x;
fun get_second (Triple (_, y, _)) = y;
fun get_third (Triple (_, _, z)) = z;
