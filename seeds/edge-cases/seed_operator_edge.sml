(* Operator edge cases and boundary conditions *)

(* Operators at precedence boundaries *)
infix 0 lowest;
infix 9 highest;

fun a lowest b = a + b;
fun a highest b = a * b;

val r1 = 1 lowest 2 highest 3;
val r2 = 1 highest 2 lowest 3;

(* Redefining built-in operators *)
infix 7 *;
fun (a: int) * (b: int) = a + b;  (* Now * means addition *)

val confusion = 3 * 4;  (* Is this 7 or 12? *)

(* Switching between fixities *)
infix 6 @@;
fun a @@ b = a + b;

val r3 = 1 @@ 2 @@ 3;  (* Non-associative *)

infixl 6 @@;
fun a @@ b = a + b;

val r4 = 1 @@ 2 @@ 3;  (* Now left-associative *)

infixr 6 @@;
fun a @@ b = a + b;

val r5 = 1 @@ 2 @@ 3;  (* Now right-associative *)

(* Make it nonfix *)
nonfix @@;

val r6 = op @@ (1, 2);

(* Single-character operators *)
infix 6 +;
infix 6 -;
infix 6 *;
infix 6 /;

fun (a: int) + (b: int) = a + b;
fun (a: int) - (b: int) = a - b;

(* Operators that look like reserved words *)
infix 6 and_;
infix 6 or_;

fun a and_ b = a + b;
fun a or_ b = a * b;

(* Empty-looking operators *)
infix 6 _;

fun a _ b = a + b;

val r7 = 5 _ 3;

(* Operators with special meaning chars *)
infix 6 ::;  (* Conflicts with built-in cons? *)
infix 6 =>;  (* Looks like case syntax *)
infix 6 |;   (* Looks like pattern match *)

(* Very long operator chains *)
val chain = 1 highest 2 highest 3 highest 4 highest 5 highest 6 highest 7 highest 8;

(* Operators next to each other without spaces *)
infix 6 +++;
fun a +++ b = a + b;

val nospace = 1+++2+++3+++4;

(* Operator precedence with parentheses *)
val p1 = (1 lowest 2) highest 3;
val p2 = 1 lowest (2 highest 3);

(* Mixing symbolic and alphanumeric *)
infix 6 add;
infix 7 mul;

fun a add b = a + b;
fun a mul b = a * b;

val r8 = 2 mul 3 add 4;

(* Operator with function application *)
fun f x = x + 1;

infix 6 $$;
fun g $$ x = g x;

val r9 = f $$ 5;

(* Chaining different operators *)
infixl 6 ++;
infixr 6 --;
infix 6 ><;

fun a ++ b = a + b;
fun a -- b = a - b;
fun a >< b = a * b;

val r10 = 1 ++ 2 -- 3 >< 4;  (* How does this parse? *)
