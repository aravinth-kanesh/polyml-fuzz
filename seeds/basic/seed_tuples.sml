(* Tuples and records *)

val pair = (1, 2);
val triple = (1, 2, 3);
val nested = ((1, 2), (3, 4));

fun fst (x, y) = x;
fun snd (x, y) = y;

fun swap (x, y) = (y, x);

val quad = (1, 2, 3, 4);
val big_tuple = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

fun add_pairs ((a, b), (c, d)) = (a + c, b + d);

val result = add_pairs ((1, 2), (3, 4));
