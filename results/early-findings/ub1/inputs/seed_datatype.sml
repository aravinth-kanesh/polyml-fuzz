datatype expr =
    Const of int
  | Add of expr * expr
  | Mul of expr * expr

fun eval (Const n) = n
  | eval (Add (x, y)) = eval x + eval y
  | eval (Mul (x, y)) = eval x * eval y

val _ = eval (Add (Const 2, Mul (Const 3, Const 4)))
