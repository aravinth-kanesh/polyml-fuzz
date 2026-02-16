(* Conditionals and boolean expressions *)

fun max (a, b) = if a > b then a else b;
fun min (a, b) = if a < b then a else b;

fun sign x =
  if x > 0 then 1
  else if x < 0 then ~1
  else 0;

val result = if true andalso false then 1 else 2;
val result2 = if true orelse false then 3 else 4;

fun factorial n =
  if n <= 0 then 1
  else n * factorial (n - 1);

val test = factorial 10;
