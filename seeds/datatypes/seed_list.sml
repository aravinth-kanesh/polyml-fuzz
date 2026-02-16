(* List operations and recursive functions *)

fun length [] = 0
  | length (x::xs) = 1 + length xs;

fun append [] ys = ys
  | append (x::xs) ys = x :: append xs ys;

fun reverse [] = []
  | reverse (x::xs) = append (reverse xs) [x];

fun map f [] = []
  | map f (x::xs) = f x :: map f xs;

val nums = [1, 2, 3, 4, 5];
val doubled = map (fn x => x * 2) nums;
val rev_nums = reverse nums;
val len = length nums;
