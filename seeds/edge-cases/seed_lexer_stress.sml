(* Lexer stress test - token boundaries *)

(* No spaces between tokens *)
val a=1;val b=2;val c=a+b*2;

(* Excessive spaces *)
val   x   =   1   +   2   *   3   ;

(* Mixed whitespace *)
val	y	=	1	+	2;  (* tabs *)

(* Consecutive operators *)
val z = 1+-2*~3;

(* Identifier token boundaries *)
val andalso_ = 1;
val _andalso = 2;
val and_also = 3;

(* Numbers adjacent to identifiers *)
val x123 = 1;
val x_123 = 2;
val _123 = 3;

(* Dots in different contexts *)
val r = 1.5;
val r2 = 1.5e10;
(* val r3 = 1.;  (* May be invalid *) *)

(* Underscores *)
val _ = 5;  (* Wildcard *)
val _x = 6;  (* Valid identifier *)
val x_ = 7;  (* Valid identifier *)
val __ = 8;  (* Valid identifier *)

(* Quotes and primes *)
val x' = 1;
val x'' = 2;
val x''' = 3;

(* Reserved words as parts of identifiers *)
val letter = 1;
val in_valid = 2;
val end_ing = 3;
val if_clause = 4;

(* Hexadecimal token boundaries *)
val h1 = 0x10;
val h2 = 0xABC;
val h3 = 0xFF;

(* Word literals *)
val w1 = 0w10;
val w2 = 0w255;
val w3 = 0wxFF;

(* String token edge cases *)
val s1 = "";
val s2 = "a";
val s3 = "\"";
val s4 = "\\";

(* Character tokens *)
val c1 = #"a";
val c2 = #"\n";
val c3 = #"\"";

(* Long lines *)
val long_expression = 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12 + 13 + 14 + 15 + 16 + 17 + 18 + 19 + 20;

(* Parentheses and brackets without spaces *)
val p1 = (1+2)*(3+4);
val p2 = ((((1))));
val l1 = [1,2,3,4,5];
val l2 = [[[[1]]]];

(* Semicolons *)
val s1 = 1; val s2 = 2; val s3 = 3;

(* Colons *)
val typed : int = 5;

(* Arrows *)
fun f1 x => x + 1;  (* Invalid syntax but tests => *)
type t1 = int -> int;

(* Bars *)
fun f 1 | f 2 = 0 | f _ = 1;  (* Tests | boundaries *)

(* Equals in different contexts *)
val eq1 = 1 = 1;  (* Comparison *)
val eq2 = 1;      (* Binding *)

(* Commas *)
val tuple = (1,2,3,4,5);
val list = [1,2,3,4,5];

(* At symbols *)
val concat = [1] @ [2] @ [3];

(* Exclamation *)
val r = ref 5;
val v = !r;

(* Carets *)
val str = "a" ^ "b" ^ "c";

(* Tildes (negation) *)
val neg = ~5;
val double_neg = ~~5;

(* Asterisks in types vs multiplication *)
val prod = 2 * 3;
type pair = int * int;
