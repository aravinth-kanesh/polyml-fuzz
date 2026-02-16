(* Operator associativity *)

(* Left associative *)
infixl 6 +-+;
infixl 5 *-*;

fun a +-+ b = a + b;
fun a *-* b = a * b;

val r1 = 1 +-+ 2 +-+ 3 +-+ 4;        (* Left: (((1+2)+3)+4) *)
val r2 = 2 *-* 3 *-* 4;              (* Left: ((2*3)*4) *)

(* Right associative *)
infixr 6 -+-;
infixr 5 -*-;

fun a -+- b = a + b;
fun a -*- b = a * b;

val r3 = 1 -+- 2 -+- 3 -+- 4;        (* Right: (1+(2+(3+4))) *)
val r4 = 2 -*- 3 -*- 4;              (* Right: (2*(3*4)) *)

(* Non-associative (infix without l/r) *)
infix 6 <+>;
infix 5 <*>;

fun a <+> b = a + b;
fun a <*> b = a * b;

val r5 = 10 <+> 20;                  (* OK: single use *)
val r6 = 5 <*> 3;                    (* OK: single use *)
(* val r7 = 1 <+> 2 <+> 3; *)        (* Would be error: needs parens *)

(* Testing associativity differences *)
infixl 4 @@;
infixr 4 $$;

fun f @@ x = f x;
fun f $$ x = f x;

fun double x = x * 2;
fun inc x = x + 1;

val r8 = double @@ inc @@ 5;         (* Left: ((double inc) 5) - likely error *)
val r9 = double $$ inc $$ 5;         (* Right: (double (inc 5)) = 12 *)
