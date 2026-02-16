(* Local declarations and scoping *)

local
  val secret = 42
  fun helper x = x + secret
in
  val public = helper 10
end;

fun complex_function x =
  let
    val double = x * 2
    val triple = x * 3
    fun add a b = a + b
  in
    add double triple
  end;

local
  datatype internal = A | B | C
  fun process A = 1
    | process B = 2
    | process C = 3
in
  val result = process A + process B + process C
end;
