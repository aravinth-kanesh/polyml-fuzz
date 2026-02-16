(* Ambiguous or tricky syntax cases *)

(* Negative number vs subtraction *)
val x = 5-3;      (* Subtraction: 5 - 3 *)
val y = 5 ~3;     (* Two values or error? *)
val z = ~3;       (* Negative 3 *)
val w = ~~3;      (* Double negation *)
val v = ~~~3;     (* Triple negation *)

(* Function application vs multiplication *)
val a = f x;      (* Function application if f exists *)
(* val b = f(x);  (* Same as above *) *)

(* Tuple vs parenthesized expression *)
val t1 = (1);     (* Just 1 *)
val t2 = (1, 2);  (* Tuple *)
val t3 = ((1));   (* Still just 1 *)

(* List vs infix cons *)
val l1 = [1, 2, 3];
val l2 = 1 :: 2 :: 3 :: [];
val l3 = 1 :: [2, 3];
val l4 = [1] @ [2] @ [3];

(* Record vs labeled pattern *)
val r = {x = 1, y = 2};
val {x = a, y = b} = r;
val {x, y} = r;  (* Punning *)

(* Case vs if-then-else *)
val c1 = case true of true => 1 | false => 0;
val c2 = if true then 1 else 0;

(* Let vs local *)
val le1 = let val x = 1 in x + 2 end;

local
  val secret = 42
in
  val public = secret + 1
end;

(* Nested structures with same names *)
structure A = struct val x = 1 end;
structure B = struct val x = 2; structure A = struct val x = 3 end end;

val b1 = A.x;      (* 1 *)
val b2 = B.x;      (* 2 *)
val b3 = B.A.x;    (* 3 *)

(* Type annotations in different positions *)
val typed1 : int = 5;
val typed2 = 5 : int;
val typed3 = (5 : int);

fun f1 (x : int) = x + 1;
fun f2 x : int = x + 1;

(* Operator sections ambiguity *)
infix 6 +++;
fun a +++ b = a + b;

val add5 = op +++ (5, 3);
(* val partial = op +++ 5;  (* Would be partial application if supported *) *)

(* As-patterns *)
fun dup (lst as (x :: xs)) = lst @ lst
  | dup [] = [];

(* Anonymous function vs function declaration *)
val anon = fn x => x + 1;
fun named x = x + 1;

(* Equality vs pattern matching *)
val eq_test = (1 = 1);
val pat_test = case 1 of 1 => true | _ => false;
