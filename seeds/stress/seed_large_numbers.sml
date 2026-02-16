(* Large numeric literals to stress number parsing *)

val small_int = 42;
val medium_int = 123456789;
val large_int = 999999999999999999;
val very_large_int = 123456789012345678901234567890;

(* Negative numbers *)
val neg_small = ~42;
val neg_large = ~999999999999999999;

(* Hexadecimal literals *)
val hex1 = 0x0;
val hex2 = 0xFF;
val hex3 = 0xDEADBEEF;
val hex4 = 0xFFFFFFFFFFFFFFFF;
val hex5 = 0x123456789ABCDEF0;

(* Word literals *)
val word1 = 0w0;
val word2 = 0w255;
val word3 = 0w4294967295;
val word4 = 0wxFF;
val word5 = 0wxDEADBEEF;

(* Real numbers *)
val real1 = 0.0;
val real2 = 3.14159265358979323846;
val real3 = 2.718281828459045;
val real4 = 1.414213562373095;
val real5 = 123456789.987654321;

(* Scientific notation *)
val sci1 = 1.0e10;
val sci2 = 1.23e~10;
val sci3 = 9.99999e100;
val sci4 = 1.0E~100;
val sci5 = 6.022e23;  (* Avogadro's number *)

(* Very small numbers *)
val tiny1 = 0.000000000001;
val tiny2 = 1e~100;
val tiny3 = 0.123456789012345678901234567890;

(* Edge cases *)
val max_like = 9223372036854775807;  (* Near Int64.maxInt *)
val leading_zeros = 000000123;
val trailing_zeros = 123000000;

(* Arithmetic with large numbers *)
val sum = 999999999 + 888888888 + 777777777;
val product = 123456 * 789012;
val difference = 999999999999 - 111111111111;

(* Mixed bases in same expression *)
val mixed = 0xFF + 255 + 0w255;

(* Real number edge cases *)
val real_max = 1.7976931348623157e308;
val real_min = 2.2250738585072014e~308;
val real_inf_like = 1e308;
val real_zero = 0.0;
val real_neg_zero = ~0.0;

(* Numeric patterns *)
fun classify 0 = "zero"
  | classify 1 = "one"
  | classify 1000000 = "million"
  | classify 1000000000 = "billion"
  | classify n = if n > 0 then "positive" else "negative";

(* Large integer list *)
val big_numbers = [
  1234567890,
  9876543210,
  1111111111,
  9999999999,
  5555555555,
  1234512345,
  9876098760
];
