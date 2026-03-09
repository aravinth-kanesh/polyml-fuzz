(* Numeric literal tokenisation: word (0w), hex (0x), real, scientific notation, negation (~) *)

(* Word literals (non-negative integers with 0w prefix) *)
val w0 : word = 0w0;
val w1 : word = 0w1;
val w255 : word = 0w255;
val w_max : word = 0w4294967295;

(* Hexadecimal word literals *)
val wh0 : word = 0wx0;
val wh1 : word = 0wxFF;
val wh2 : word = 0wxDEAD;
val wh3 : word = 0wxCAFEBABE;

(* Hexadecimal integer literals *)
val h0 = 0x0;
val h1 = 0xFF;
val h2 = 0x7FFFFFFF;
val h3 = 0x10;
val h4 = 0xABCDEF;

(* Real / float literals *)
val r0 : real = 0.0;
val r1 : real = 1.0;
val r2 : real = 3.14159;
val r3 : real = 0.001;
val r4 : real = 100.0;

(* Scientific notation (e suffix) *)
val e0 : real = 1.0e0;
val e1 : real = 1.5e10;
val e2 : real = 2.5e~3;
val e3 : real = 1.0e100;
val e4 : real = 6.022e23;

(* Negation prefix ~ for integers *)
val n0 = ~1;
val n1 = ~0;
val n2 = ~1073741824;
val n3 = ~42;

(* Negation prefix ~ for reals *)
val nr0 : real = ~0.0;
val nr1 : real = ~1.5;
val nr2 : real = ~3.14;
val nr3 : real = ~1.0e10;
val nr4 : real = ~2.5e~3;

(* Arithmetic mixing word, int, real via explicit conversions *)
val mixed_int : int = Word.toInt w255 + h1 + n0;
val mixed_real : real = Real.fromInt mixed_int + r3 + e2;

(* Word arithmetic *)
val wa = Word.+ (w1, wh1);
val wb = Word.andb (wh3, 0wxFFFF);
val wc = Word.orb  (0wx0F0F, 0wxF0F0);

(* Pattern matching on numeric ranges *)
fun classify (n : int) =
    if n < ~100 then "very negative"
    else if n < 0 then "negative"
    else if n = 0 then "zero"
    else if n < 100 then "positive"
    else "very positive";

val _ = classify n1;
val _ = classify 0x7F;
val _ = classify ~1;

(* String conversion of numeric literals *)
val _ = Int.toString h2;
val _ = Word.toString wh3;
val _ = Real.toString r4;
