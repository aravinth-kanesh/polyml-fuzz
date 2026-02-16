(* Operator redefinition and shadowing *)

(* Initial definition *)
infix 6 @@;
fun a @@ b = a + b;

val r1 = 5 @@ 3;  (* = 8 *)

(* Redefinition with different precedence *)
infix 8 @@;
fun a @@ b = a * b;

val r2 = 5 @@ 3;  (* = 15 *)

(* Test precedence change *)
infix 5 +++;
fun a +++ b = a + b;

val r3 = 2 @@ 3 +++ 4;  (* With @@ at 8: (2*3) + 4 = 10 *)

(* Redefine again *)
infix 4 @@;
fun a @@ b = a - b;

val r4 = 10 @@ 3;  (* = 7 *)
val r5 = 2 @@ 3 +++ 4;  (* With @@ at 4: 2 @ (3+4) or (2@3) + 4? *)

(* Local shadowing *)
val r6 =
  let
    infix 6 @@
    fun a @@ b = a div b
  in
    10 @@ 2
  end;  (* = 5 in local scope *)

(* Back to previous definition *)
val r7 = 10 @@ 2;  (* Uses definition from line 14 *)

(* Shadowing with same precedence but different associativity *)
infixl 6 ***;
fun a *** b = a * b;

val r8 = 2 *** 3 *** 4;  (* Left: (2*3)*4 *)

infixr 6 ***;
fun a *** b = a * b;

val r9 = 2 *** 3 *** 4;  (* Right: 2*(3*4) *)

(* Nonfix declaration *)
nonfix @@;

val r10 = op @@ (5, 3);  (* Can only use as prefix with 'op' *)

(* Redefine as infix again *)
infix 7 @@;
fun a @@ b = a + b + 1;

val r11 = 5 @@ 3;  (* = 9 *)
