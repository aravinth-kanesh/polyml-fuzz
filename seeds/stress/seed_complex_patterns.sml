(* Complex and deeply nested pattern matching *)

(* Deeply nested tuple patterns *)
fun extract (((((a, b), c), d), e), f) = a + b + c + d + e + f;

val r1 = extract (((((1, 2), 3), 4), 5), 6);

(* List patterns with deep nesting *)
fun sum_nested [] = 0
  | sum_nested ([x]) = x
  | sum_nested ([x, y]) = x + y
  | sum_nested ([x, y, z]) = x + y + z
  | sum_nested (x :: y :: z :: w :: rest) = x + y + z + w + sum_nested rest;

val s1 = sum_nested [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

(* Complex constructor patterns *)
datatype tree = Leaf of int | Node of tree * int * tree;

fun find_value (Leaf n) target = n = target
  | find_value (Node (Leaf l, v, Leaf r)) target = l = target orelse v = target orelse r = target
  | find_value (Node (Node (ll, lv, lr), v, Leaf r)) target =
      find_value (Node (ll, lv, lr)) target orelse v = target orelse r = target
  | find_value (Node (Leaf l, v, Node (rl, rv, rr))) target =
      l = target orelse v = target orelse find_value (Node (rl, rv, rr)) target
  | find_value (Node (left, v, right)) target =
      find_value left target orelse v = target orelse find_value right target;

(* Record patterns with many fields *)
type person = {
  first_name: string,
  last_name: string,
  age: int,
  height: real,
  weight: real,
  employed: bool,
  city: string
};

fun get_info {first_name, last_name, age, height, weight, employed, city} =
  first_name ^ " " ^ last_name ^ " from " ^ city;

val p = {
  first_name = "John",
  last_name = "Doe",
  age = 30,
  height = 180.0,
  weight = 75.0,
  employed = true,
  city = "Boston"
};

val info = get_info p;

(* As-patterns *)
fun duplicate (lst as (x :: xs)) = lst @ lst
  | duplicate [] = [];

val d1 = duplicate [1, 2, 3];

(* Layered patterns *)
fun process_pair (p as (x, y)) = if x > y then p else (y, x);

val p1 = process_pair (5, 3);
val p2 = process_pair (2, 8);

(* Wild patterns mixed with specific patterns *)
fun complex_match (0, _, 0) = 1
  | complex_match (_, 0, _) = 2
  | complex_match (x, y, 0) = x + y
  | complex_match (0, y, z) = y + z
  | complex_match (x, 0, z) = x + z
  | complex_match (x, y, z) = x + y + z;

(* Nested option patterns *)
datatype 'a option = NONE | SOME of 'a;

fun extract_nested (SOME (SOME (SOME (SOME x)))) = x
  | extract_nested (SOME (SOME (SOME NONE))) = 0
  | extract_nested (SOME (SOME NONE)) = 0
  | extract_nested (SOME NONE) = 0
  | extract_nested NONE = 0;

val e1 = extract_nested (SOME (SOME (SOME (SOME 42))));

(* Either patterns *)
datatype ('a, 'b) either = Left of 'a | Right of 'b;

fun process_either (Left (Left (Left x))) = x
  | process_either (Left (Left (Right x))) = x
  | process_either (Left (Right x)) = x
  | process_either (Right (Left x)) = x
  | process_either (Right (Right x)) = x;
