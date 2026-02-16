(* Operator precedence levels *)

infix 9 ***;
infix 8 ///;
infix 7 +++
infix 6 ---;
infix 5 <<<;
infix 4 >>>;
infix 3 %%%
infix 2 &&&;
infix 1 |||;
infix 0 ==>;

fun a *** b = a * b * 2;
fun a /// b = a div (b + 1);
fun a +++ b = a + b + 1;
fun a --- b = a - b - 1;
fun a <<< b = a * 2;
fun a >>> b = a div 2;
fun a %%% b = a mod (b + 1);
fun a &&& b = if a > 0 andalso b > 0 then 1 else 0;
fun a ||| b = if a > 0 orelse b > 0 then 1 else 0;
fun a ==> b = if a > 0 then b else 0;

(* Test precedence *)
val r1 = 10 +++ 20 *** 30;          (* Should parse as: 10 + (20 * 30) *)
val r2 = 100 /// 5 +++ 2;            (* (100 / 5) + 2 *)
val r3 = 8 <<< 2 --- 1 >>> 1;        (* Complex precedence *)
val r4 = 10 %%% 3 &&& 5;             (* (10 % 3) & 5 *)
val r5 = 1 ||| 0 ==> 42;             (* (1 | 0) => 42 *)

(* Mixing standard and custom operators *)
val r6 = 5 * 3 +++ 2 * 4;            (* (5*3) + (2*4) based on precedence *)
val r7 = 10 + 5 *** 2;               (* 10 + (5*2*2) *)
