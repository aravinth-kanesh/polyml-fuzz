(* Constructs that test error recovery *)

(* Valid code *)
val valid1 = 1 + 2;

(* Potentially problematic but valid constructs *)
val multi_underscore = __________;

(* Very long identifier *)
val very_long_identifier_name_with_many_words = 42;

(* Chained operations *)
val chain = 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10;

(* Deep nesting *)
val nest = ((((((((((1)))))))))  );

(* Multiple semicolons *)
val x1 = 1; val x2 = 2; val x3 = 3; val x4 = 4;

(* Consecutive function definitions *)
fun f1 x = x;
fun f2 x = x;
fun f3 x = x;

(* Datatype followed by val *)
datatype t = A | B;
val v = A;

(* Structure then fun *)
structure S = struct val x = 1 end;
fun use_s () = S.x;

(* Pattern match with many cases *)
fun many_cases 0 = 0
  | many_cases 1 = 1
  | many_cases 2 = 2
  | many_cases 3 = 3
  | many_cases 4 = 4
  | many_cases 5 = 5
  | many_cases _ = ~1;

(* Let with many bindings *)
val complex_let =
  let
    val a = 1
    val b = 2
    val c = 3
    fun f x = x + 1
    fun g x = x * 2
  in
    f (g (a + b + c))
  end;

(* Case with nested patterns *)
fun nested_case x =
  case x of
      (0, 0) => 0
    | (1, _) => 1
    | (_, 1) => 2
    | (a, b) => a + b;

(* Higher-order functions *)
fun map f [] = []
  | map f (x :: xs) = f x :: map f xs;

val mapped = map (fn x => x + 1) [1, 2, 3];

(* Operators with weird spacing *)
val ops = 1 + 2 * 3 - 4 div 2;

(* Record with many fields *)
val rec_val = {a = 1, b = 2, c = 3, d = 4, e = 5};

(* Valid code after potential errors *)
val recovery = 100;

(* Final valid statement *)
val final = 999;
