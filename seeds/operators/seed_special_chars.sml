(* Operators with special characters *)

infix 6 +++;
infix 6 ---;
infix 7 ***;
infix 7 ///;
infix 5 <<<;
infix 5 >>>;
infix 4 ^^^;
infix 4 &&&;
infix 3 |||;
infix 6 <=>;
infix 5 >>=;
infix 5 =<<;

fun a +++ b = a + b;
fun a --- b = a - b;
fun a *** b = a * b;
fun a /// b = a div b;
fun a <<< b = a * 2;
fun a >>> b = a div 2;
fun a ^^^ b = a * a;  (* square *)
fun a &&& b = a;
fun a ||| b = b;
fun a <=> b = if a = b then 0 else if a < b then ~1 else 1;
fun a >>= b = a + b;
fun a =<< b = b + a;

(* Mix of alphanumeric and symbolic *)
infix 6 `add`;
infix 7 `mul`;

fun a `add` b = a + b;
fun a `mul` b = a * b;

val r1 = 5 `add` 3;
val r2 = 4 `mul` 7;
val r3 = 2 `mul` 3 `add` 4;

(* Operators with underscores *)
infix 6 _+_;
infix 6 _-_;

fun a _+_ b = a + b;
fun a _-_ b = a - b;

val r4 = 10 _+_ 5 _-_ 3;

(* Operators with primes *)
infix 6 +';
infix 6 *';

fun a +' b = a + b + 1;
fun a *' b = a * b + 1;

val r5 = 5 +' 3;
val r6 = 4 *' 2;
