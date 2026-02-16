(* Operator overloading patterns *)

infix 6 ++;
infix 7 **;

(* Integer operators *)
fun (a: int) ++ (b: int) = a + b;
fun (a: int) ** (b: int) = a * b;

(* Real operators *)
fun (a: real) ++ (b: real) = a + b;
fun (a: real) ** (b: real) = a * b;

val i1 = 5 ++ 3;       (* int *)
val i2 = 4 ** 2;       (* int *)

val r1 = 5.0 ++ 3.0;   (* real *)
val r2 = 4.0 ** 2.0;   (* real *)

(* Polymorphic operators *)
infix 5 @@;

fun f @@ x = f x;

val r3 = (fn x => x + 1) @@ 5;
val r4 = (fn x => x ^ "!") @@ "hello";

(* List operators *)
infixr 5 +++;

fun [] +++ ys = ys
  | (x :: xs) +++ ys = x :: (xs +++ ys);

val list1 = [1, 2, 3] +++ [4, 5, 6];
val list2 = ["a", "b"] +++ ["c", "d"];

(* Tuple operators *)
infix 6 <+>;
infix 7 <*>;

fun (a, b) <+> (c, d) = (a + c, b + d);
fun (a, b) <*> (c, d) = (a * c, b * d);

val t1 = (1, 2) <+> (3, 4);
val t2 = (2, 3) <*> (4, 5);

(* Option operators *)
infix 5 <|>;

fun SOME x <|> _ = SOME x
  | NONE <|> y = y;

val o1 = SOME 5 <|> SOME 10;
val o2 = NONE <|> SOME 42;
val o3 = NONE <|> NONE;

(* Function composition *)
infixr 9 oo;

fun (f oo g) x = f (g x);

val h = (fn x => x * 2) oo (fn x => x + 1);
val result = h 5;
