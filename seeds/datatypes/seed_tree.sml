(* Binary tree datatype *)

datatype 'a tree =
    Leaf
  | Node of 'a * 'a tree * 'a tree;

fun size Leaf = 0
  | size (Node (_, left, right)) = 1 + size left + size right;

fun height Leaf = 0
  | height (Node (_, left, right)) = 1 + Int.max (height left, height right);

fun inorder Leaf = []
  | inorder (Node (v, left, right)) =
      inorder left @ [v] @ inorder right;

val tree = Node (5,
                  Node (3, Leaf, Leaf),
                  Node (7, Leaf, Node (9, Leaf, Leaf)));

val tree_size = size tree;
val tree_height = height tree;
val sorted = inorder tree;
