(* Maximum complexity - combining all stress factors *)

(* Deep nesting + long identifiers + many bindings *)
structure VeryLongStructureNameWithManyWordsInIt =
struct
  structure NestedStructureAlsoWithALongName =
  struct
    structure DeeperNestedStructureWithEvenLongerName =
    struct
      val very_long_variable_name_inside_deeply_nested_structure = 42

      fun extremely_long_function_name_that_does_something_simple x =
        let
          val local_variable_with_unnecessarily_long_name = x + 1
          val another_local_variable_also_with_long_name = x * 2
          val yet_another_variable_name_that_goes_on = x - 1
        in
          local_variable_with_unnecessarily_long_name +
          another_local_variable_also_with_long_name +
          yet_another_variable_name_that_goes_on
        end

      datatype complex_nested_type_with_long_name =
          Constructor1_with_long_name of int * int * int
        | Constructor2_with_long_name of string * string * string
        | Constructor3_with_long_name of bool * bool * bool

      (* Deeply nested comments *)
      (* Level 1 (* Level 2 (* Level 3 (* Level 4 (* Level 5 *) *) *) *) *)

      (* Complex pattern matching with deep nesting *)
      fun complex_pattern_match (Constructor1_with_long_name (a, b, c)) =
            ((((a + b) + c) * 2) - 1)
        | complex_pattern_match (Constructor2_with_long_name (s1, s2, s3)) =
            size (s1 ^ s2 ^ s3)
        | complex_pattern_match (Constructor3_with_long_name (b1, b2, b3)) =
            if b1 andalso b2 andalso b3 then 1 else 0
    end
  end
end;

(* Large case expression with deep nesting *)
fun massive_case_expression x =
  case x of
      (0, (0, (0, 0))) =>
        let val r1 = 1 in
        let val r2 = r1 + 1 in
        let val r3 = r2 + 1 in
          r3
        end end end
    | (1, (1, (1, 1))) =>
        let val r1 = 2 in
        let val r2 = r1 * 2 in
        let val r3 = r2 * 2 in
          r3
        end end end
    | (2, (2, (2, 2))) =>
        let val r1 = 3 in
        let val r2 = r1 - 1 in
        let val r3 = r2 - 1 in
          r3
        end end end
    | (a, (b, (c, d))) =>
        let val sum = a + b + c + d in
        let val product = a * b * c * d in
        let val difference = sum - product in
          if difference > 0 then difference else ~difference
        end end end;

(* Many operators with different precedences *)
infixr 9 ^^^;
infixl 8 ***;
infixr 7 //;
infixl 6 ++;
infixr 5 --;
infixl 4 <<<;
infixr 3 >>>;
infixl 2 &&&;
infixr 1 |||;

fun a ^^^ b = a * a;
fun a *** b = a * b * 2;
fun a // b = a div (b + 1);
fun a ++ b = a + b + 1;
fun a -- b = a - b - 1;
fun a <<< b = a * 2;
fun a >>> b = a div 2;
fun a &&& b = a + b;
fun a ||| b = a * b;

val complex_expression =
  1 ||| 2 &&& 3 >>> 4 <<< 5 -- 6 ++ 7 // 8 *** 9 ^^^ 10;

(* Very long string with escapes in deeply nested structure *)
val long_string_in_complex_context =
  let
    val s1 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n\n\n\n\n"
    val s2 = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\t\t\t\t\t"
    val s3 = "cccccccccccccccccccccccccccccccccccccccccccccc\\\\\\\\\\"
  in
    s1 ^ s2 ^ s3 ^ s1 ^ s2 ^ s3 ^ s1 ^ s2 ^ s3
  end;

(* Deep recursion with complex types *)
fun deep_recursive_function 0 acc = acc
  | deep_recursive_function n acc =
      deep_recursive_function
        (n - 1)
        (acc +
         (let val x = n * 2 in
          let val y = x + 1 in
          let val z = y * 3 in
            x + y + z
          end end end));

val recursion_result = deep_recursive_function 50 0;
