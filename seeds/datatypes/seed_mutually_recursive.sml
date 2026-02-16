(* Mutually recursive datatypes *)

datatype expr =
    Num of int
  | Var of string
  | BinOp of binop * expr * expr
  | UnOp of unop * expr
and binop =
    Add
  | Sub
  | Mul
  | Div
and unop =
    Neg
  | Abs;

fun eval_expr (Num n) = n
  | eval_expr (Var _) = 0
  | eval_expr (BinOp (op_code, e1, e2)) =
      eval_binop op_code (eval_expr e1) (eval_expr e2)
  | eval_expr (UnOp (op_code, e)) =
      eval_unop op_code (eval_expr e)
and eval_binop Add a b = a + b
  | eval_binop Sub a b = a - b
  | eval_binop Mul a b = a * b
  | eval_binop Div a b = a div b
and eval_unop Neg a = ~a
  | eval_unop Abs a = if a < 0 then ~a else a;

(* Another mutual recursion example *)
datatype person = Person of string * int * person list;

fun find_oldest [] = NONE
  | find_oldest ((Person (name, age, children)) :: rest) =
      case (find_oldest_in_children children, find_oldest rest) of
          (NONE, NONE) => SOME (name, age)
        | (SOME (n1, a1), NONE) => if a1 > age then SOME (n1, a1) else SOME (name, age)
        | (NONE, SOME (n2, a2)) => if a2 > age then SOME (n2, a2) else SOME (name, age)
        | (SOME (n1, a1), SOME (n2, a2)) =>
            if a1 >= a2 andalso a1 >= age then SOME (n1, a1)
            else if a2 >= a1 andalso a2 >= age then SOME (n2, a2)
            else SOME (name, age)
and find_oldest_in_children children = find_oldest children;
