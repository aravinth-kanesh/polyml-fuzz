(* Complex algebraic datatype *)

datatype expr =
    Const of int
  | Var of string
  | Add of expr * expr
  | Sub of expr * expr
  | Mul of expr * expr
  | Div of expr * expr
  | Let of string * expr * expr;

fun eval env (Const n) = n
  | eval env (Var x) = 0  (* simplified *)
  | eval env (Add (e1, e2)) = eval env e1 + eval env e2
  | eval env (Sub (e1, e2)) = eval env e1 - eval env e2
  | eval env (Mul (e1, e2)) = eval env e1 * eval env e2
  | eval env (Div (e1, e2)) = eval env e1 div eval env e2
  | eval env (Let (x, e1, e2)) = eval env e2;

val program = Add (Mul (Const 2, Const 3), Const 4);
val result = eval [] program;
