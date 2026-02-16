(* Higher-order functions *)

fun apply f x = f x;
fun compose f g x = f (g x);
fun twice f x = f (f x);

val increment = fn x => x + 1;
val double = fn x => x * 2;

val add_one_twice = twice increment;
val quad = twice double;

fun curry f x y = f (x, y);
fun uncurry f (x, y) = f x y;

val curried_add = curry (fn (a, b) => a + b);
val result = curried_add 10 20;

fun fold f init [] = init
  | fold f init (x::xs) = fold f (f (init, x)) xs;

val sum = fold (fn (acc, x) => acc + x) 0 [1, 2, 3, 4, 5];
