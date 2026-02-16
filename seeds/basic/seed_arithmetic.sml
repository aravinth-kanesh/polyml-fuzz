(* Basic arithmetic and let expressions *)

val x = 42;
val y = x + 10;
val z = x * y - 100;

fun square n = n * n;
fun cube n = n * n * n;

val result = square 5 + cube 3;

let
  val a = 10
  val b = 20
in
  a + b * 2
end;
