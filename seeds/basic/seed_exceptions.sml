(* Exception handling *)

exception MyError;
exception ValueError of int;
exception StringError of string;

fun safe_div (a, 0) = raise Div
  | safe_div (a, b) = a div b;

fun handle_div (a, b) =
  safe_div (a, b)
  handle Div => 0;

fun test_exception n =
  if n < 0 then raise ValueError n
  else if n = 0 then raise MyError
  else n * 2;

val result = test_exception 5
  handle MyError => ~1
       | ValueError v => v
       | _ => ~99;
