(* References and mutable state *)

val counter = ref 0;

fun increment () = counter := !counter + 1;
fun decrement () = counter := !counter - 1;
fun get () = !counter;
fun reset () = counter := 0;

val _ = increment ();
val _ = increment ();
val _ = increment ();
val current = get ();
val _ = decrement ();
val after_dec = get ();

(* Multiple references *)
val x = ref 10;
val y = ref 20;
val z = ref 30;

fun swap (a, b) =
  let val temp = !a
  in a := !b; b := temp
  end;

val _ = swap (x, y);

(* Reference to reference *)
val r1 = ref 5;
val r2 = ref r1;

val v1 = !(!r2);
val _ = (!r2) := 10;
val v2 = !r1;

(* Array-like usage with references *)
val arr = (ref 1, ref 2, ref 3, ref 4, ref 5);

fun get_elem (r1, r2, r3, r4, r5) 0 = !r1
  | get_elem (r1, r2, r3, r4, r5) 1 = !r2
  | get_elem (r1, r2, r3, r4, r5) 2 = !r3
  | get_elem (r1, r2, r3, r4, r5) 3 = !r4
  | get_elem (r1, r2, r3, r4, r5) 4 = !r5
  | get_elem _ _ = 0;

val elem0 = get_elem arr 0;
val elem2 = get_elem arr 2;

(* Reference patterns *)
datatype 'a reflist = Empty | Node of 'a ref * 'a reflist;

fun make_reflist [] = Empty
  | make_reflist (x :: xs) = Node (ref x, make_reflist xs);

fun sum_reflist Empty = 0
  | sum_reflist (Node (r, rest)) = !r + sum_reflist rest;

val rlist = make_reflist [1, 2, 3, 4, 5];
val sum = sum_reflist rlist;
