(* Option type and maybe monad *)

datatype 'a option = NONE | SOME of 'a;

fun get_or_default NONE default = default
  | get_or_default (SOME v) default = v;

fun map_option f NONE = NONE
  | map_option f (SOME v) = SOME (f v);

fun bind_option NONE f = NONE
  | bind_option (SOME v) f = f v;

fun safe_head [] = NONE
  | safe_head (x::xs) = SOME x;

fun safe_nth [] n = NONE
  | safe_nth (x::xs) 0 = SOME x
  | safe_nth (x::xs) n = safe_nth xs (n - 1);

val test1 = safe_head [1, 2, 3];
val test2 = safe_head [];
val mapped = map_option (fn x => x * 2) (SOME 21);
