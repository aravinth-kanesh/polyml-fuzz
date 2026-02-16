(* Operator edge cases and corner cases *)

(* Single character operators *)
infix 6 +;
infix 6 -;
infix 7 *;
infix 7 /;

fun (a: int) + (b: int) = a + b;  (* Shadows built-in *)
fun (a: int) - (b: int) = a - b;
fun (a: int) * (b: int) = a * b;
fun (a: int) / (b: int) = a div b;

(* Very long operator names *)
infix 5 very_long_operator_name_that_goes_on_and_on;
fun a very_long_operator_name_that_goes_on_and_on b = a + b;

val r1 = 5 very_long_operator_name_that_goes_on_and_on 3;

(* Operators with numbers *)
infix 6 +1;
infix 6 *2;
infix 6 ^3;

fun a +1 b = a + b + 1;
fun a *2 b = a * b * 2;
fun a ^3 b = a * a * a + b;

val r2 = 5 +1 3;
val r3 = 4 *2 2;
val r4 = 2 ^3 1;

(* Operators that look like keywords *)
infix 6 andalso_;
infix 6 orelse_;
infix 6 if_;

fun a andalso_ b = a + b;
fun a orelse_ b = a - b;
fun a if_ b = a * b;

val r5 = 5 andalso_ 3;
val r6 = 10 orelse_ 4;
val r7 = 6 if_ 2;

(* Mixing symbolic and alphanumeric in operator name *)
infix 6 add_;
infix 6 _sub;
infix 6 _mul_;

fun a add_ b = a + b;
fun a _sub b = a - b;
fun a _mul_ b = a * b;

val r8 = 5 add_ 3;
val r9 = 10 _sub 4;
val r10 = 6 _mul_ 2;

(* Operators with maximum precedence *)
infix 0 low;
infix 9 high;

fun a low b = a + b;
fun a high b = a * b;

val r11 = 1 low 2 high 3;  (* Should be: 1 + (2 * 3) = 7 *)
val r12 = 1 high 2 low 3;  (* Should be: (1 * 2) + 3 = 5 *)

(* Empty-looking operators (just underscores) *)
infix 6 _;
infix 6 __;
infix 6 ___;

fun a _ b = a + b;
fun a __ b = a * b;
fun a ___ b = a - b;

val r13 = 5 _ 3;
val r14 = 4 __ 2;
val r15 = 10 ___ 3;

(* Operators with special regex-like chars *)
infix 6 .*;
infix 6 +?;
infix 6 |+;

fun a .* b = a * b;
fun a +? b = if b > 0 then a + b else a;
fun a |+ b = a + b;

val r16 = 5 .* 3;
val r17 = 10 +? 5;
val r18 = 7 |+ 2;
