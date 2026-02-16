(* Boundary value testing *)

(* Empty constructs *)
val empty_string = "";
val empty_list = [];
val empty_tuple = ();

fun empty_fun () = ();

datatype empty_datatype = EmptyConstructor;

structure EmptyStruct = struct end;

(* Single element *)
val single_char = "a";
val single_list = [1];
val single_tuple = (1,);  (* May or may not be valid *)

(* Minimum and maximum like values *)
val zero = 0;
val one = 1;
val neg_one = ~1;
val max_small = 127;
val min_small = ~128;

(* Very nested but minimal *)
val nested_empty = [[[[]]]];
val nested_unit = ((((()))));

(* Edge case patterns *)
fun match_empty [] = 0
  | match_empty _ = 1;

fun match_one [x] = x
  | match_one _ = 0;

fun match_two [x, y] = x + y
  | match_two _ = 0;

(* Minimal let *)
val min_let = let in 0 end;  (* May be invalid *)

(* Minimal case *)
val min_case = case () of () => 1;

(* Minimal function *)
fun min () = ();

(* Minimal datatype *)
datatype unit_like = Unit;

(* Minimal signature *)
signature MIN_SIG = sig end;

(* Minimal structure *)
structure MinStruct : MIN_SIG = struct end;

(* Zero-length identifiers would be invalid *)
(* val  = 1; *)

(* Single-char identifiers *)
val a = 1;
val b = 2;
val x = 3;
val y = 4;
val z = 5;

(* Boundary in numbers *)
val zero_int = 0;
val zero_real = 0.0;
val zero_word = 0w0;

(* Just above/below boundaries *)
val pos_one = 1;
val neg_one = ~1;

(* Empty function body attempts *)
fun try_empty x = ();

(* Minimal arithmetic *)
val min_add = 0 + 0;
val min_sub = 0 - 0;
val min_mul = 0 * 0;
val min_div = 1 div 1;

(* Nested empty structures *)
structure Outer = struct
  structure Inner = struct
  end
end;
