(* Datatype equality and comparison *)

datatype color = Red | Green | Blue | Yellow | Black | White;

fun eq_color Red Red = true
  | eq_color Green Green = true
  | eq_color Blue Blue = true
  | eq_color Yellow Yellow = true
  | eq_color Black Black = true
  | eq_color White White = true
  | eq_color _ _ = false;

datatype 'a option = NONE | SOME of 'a;

fun eq_option eq NONE NONE = true
  | eq_option eq (SOME x) (SOME y) = eq x y
  | eq_option eq _ _ = false;

fun eq_int (x: int) (y: int) = x = y;

val opt1 = SOME 5;
val opt2 = SOME 5;
val result = eq_option eq_int opt1 opt2;

(* List equality *)
datatype 'a list = Nil | Cons of 'a * 'a list;

fun eq_list eq Nil Nil = true
  | eq_list eq (Cons (x, xs)) (Cons (y, ys)) = eq x y andalso eq_list eq xs ys
  | eq_list eq _ _ = false;

(* Tree equality *)
datatype 'a tree = Leaf | Node of 'a * 'a tree * 'a tree;

fun eq_tree eq Leaf Leaf = true
  | eq_tree eq (Node (x, l1, r1)) (Node (y, l2, r2)) =
      eq x y andalso eq_tree eq l1 l2 andalso eq_tree eq r1 r2
  | eq_tree eq _ _ = false;

val tree1 = Node (1, Node (2, Leaf, Leaf), Node (3, Leaf, Leaf));
val tree2 = Node (1, Node (2, Leaf, Leaf), Node (3, Leaf, Leaf));
val trees_equal = eq_tree eq_int tree1 tree2;
