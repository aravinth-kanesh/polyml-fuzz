(* Mixed fixity: infix, infixl, infixr, nonfix *)

(* Define several operators with different fixity *)
infixl 6 <+;
infixr 6 +>;
infix 6 <+>;

fun a <+ b = a + b;
fun a +> b = a + b;
fun a <+> b = a + b;

(* These parse differently due to associativity *)
val r1 = 1 <+ 2 <+ 3;     (* Left: ((1+2)+3) = 6 *)
val r2 = 1 +> 2 +> 3;     (* Right: (1+(2+3)) = 6 *)
(* val r3 = 1 <+> 2 <+> 3; *)  (* Error: non-associative needs parens *)

val r4 = (1 <+> 2) <+> 3;  (* OK with explicit parens *)
val r5 = 1 <+> (2 <+> 3);  (* OK with explicit parens *)

(* Prefix vs infix *)
infixl 7 **;
fun a ** b = a * b;

val r6 = 3 ** 4;           (* infix: 12 *)
val r7 = op ** (3, 4);     (* prefix with op: 12 *)

(* Make it nonfix *)
nonfix **;

(* val r8 = 3 ** 4; *)     (* Error: ** is no longer infix *)
val r9 = ** (3, 4);        (* OK: now a regular function *)

(* Restore as infixr *)
infixr 8 **;
fun a ** b = a * b;

val r10 = 2 ** 3 ** 4;     (* Right: 2**(3**4) *)

(* Complex mixing *)
infixl 5 <<<;
infixr 5 >>>;
infix 5 <=>;

fun a <<< b = a * 2 + b;
fun a >>> b = a + b * 2;
fun a <=> b = (a + b) div 2;

val r11 = 1 <<< 2 <<< 3;            (* Left *)
val r12 = 1 >>> 2 >>> 3;            (* Right *)
val r13 = (1 <=> 2) <=> 3;          (* Non-assoc needs parens *)

(* Interactions between fixity declarations *)
infixl 6 ++;
infixr 6 ::;  (* Built-in list cons *)

fun a ++ b = a + b;

val r14 = 1 ++ 2 ++ 3;              (* Left: 6 *)
val r15 = 1 :: 2 :: 3 :: [];        (* Right: [1,2,3] *)

(* Switching between fixities in local scope *)
local
  infixl 7 @@
  fun a @@ b = a * b
in
  val r16 = 2 @@ 3 @@ 4  (* Left: (2*3)*4 = 24 *)
end;

local
  infixr 7 @@
  fun a @@ b = a * b
in
  val r17 = 2 @@ 3 @@ 4  (* Right: 2*(3*4) = 24 *)
end;
