(* Recursive list implementation *)

datatype 'a mylist = Nil | Cons of 'a * 'a mylist;

fun length Nil = 0
  | length (Cons (_, xs)) = 1 + length xs;

fun append Nil ys = ys
  | append (Cons (x, xs)) ys = Cons (x, append xs ys);

fun reverse Nil = Nil
  | reverse (Cons (x, xs)) = append (reverse xs) (Cons (x, Nil));

fun map f Nil = Nil
  | map f (Cons (x, xs)) = Cons (f x, map f xs);

fun filter p Nil = Nil
  | filter p (Cons (x, xs)) =
      if p x then Cons (x, filter p xs)
      else filter p xs;

val nums = Cons (1, Cons (2, Cons (3, Cons (4, Cons (5, Nil)))));
val doubled = map (fn x => x * 2) nums;
val evens = filter (fn x => x mod 2 = 0) nums;
val len = length nums;
