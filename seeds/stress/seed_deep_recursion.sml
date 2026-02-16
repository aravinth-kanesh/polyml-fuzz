(* Deep recursion to stress stack handling *)

fun deep_recursion 0 = 0
  | deep_recursion n = 1 + deep_recursion (n - 1);

val r1 = deep_recursion 100;
val r2 = deep_recursion 500;
val r3 = deep_recursion 1000;

(* Mutual recursion with depth *)
fun even 0 = true
  | even n = if n < 0 then false else odd (n - 1)
and odd 0 = false
  | odd n = if n < 0 then false else even (n - 1);

val e1 = even 100;
val e2 = odd 99;
val e3 = even 500;

(* Nested function calls *)
fun f1 x = x + 1;
fun f2 x = f1 (f1 (f1 (f1 (f1 x))));
fun f3 x = f2 (f2 (f2 (f2 (f2 x))));
fun f4 x = f3 (f3 (f3 (f3 (f3 x))));
fun f5 x = f4 (f4 (f4 x));

val nested_result = f5 0;

(* Deeply nested expression evaluation *)
val expr_result =
  ((((((((((1 + 2) + 3) + 4) + 5) + 6) + 7) + 8) + 9) + 10) +
   (((((((((11 + 12) + 13) + 14) + 15) + 16) + 17) + 18) + 19) + 20));

(* Tree with deep nesting *)
datatype tree = Leaf of int | Node of tree * tree;

fun make_deep_tree 0 = Leaf 0
  | make_deep_tree n = Node (make_deep_tree (n - 1), make_deep_tree (n - 1));

fun tree_depth (Leaf _) = 1
  | tree_depth (Node (left, right)) = 1 + Int.max (tree_depth left, tree_depth right);

val t1 = make_deep_tree 5;
val d1 = tree_depth t1;

(* List operations with deep recursion *)
fun make_list 0 = []
  | make_list n = n :: make_list (n - 1);

fun sum_list [] = 0
  | sum_list (x :: xs) = x + sum_list xs;

val long_list = make_list 500;
val list_sum = sum_list long_list;

(* Continuation-passing style deep recursion *)
fun fact_cps 0 k = k 1
  | fact_cps n k = fact_cps (n - 1) (fn result => k (n * result));

val fact_result = fact_cps 20 (fn x => x);

(* Nested let expressions *)
val nested_let =
  let val x1 = 1 in
  let val x2 = x1 + 1 in
  let val x3 = x2 + 1 in
  let val x4 = x3 + 1 in
  let val x5 = x4 + 1 in
  let val x6 = x5 + 1 in
  let val x7 = x6 + 1 in
  let val x8 = x7 + 1 in
  let val x9 = x8 + 1 in
  let val x10 = x9 + 1 in
    x10
  end end end end end end end end end end;
