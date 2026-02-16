(* Nested comments (* should *) still work *)
infix 5 ++
fun x ++ y = x + y

val _ = 1 ++ 2
