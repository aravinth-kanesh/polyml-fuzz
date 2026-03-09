(* Parser error-recovery: valid SML with commented-out syntax errors as mutation base *)

(* Valid preamble so the parser has context before errors begin *)
val preamble = 42;
fun id x = x;

(* Error 1: missing right-hand side on val binding *)
(* val missing_rhs = ; *)

(* Error 2: type annotation without a following expression *)
(* val annotated : int; *)

(* Valid declaration to force resynchronisation *)
val after_error_1 = 1 + 1;

(* Error 3: incomplete function body -- fun with no equations *)
(* fun incomplete_fun; *)

(* Error 4: case expression with no arms *)
(* val bad_case = case 1 of; *)

(* Valid declaration *)
val after_error_2 = "still alive";

(* Error 5: let without in *)
(* val bad_let = let val x = 1; *)

(* Error 6: unclosed parenthesis in expression *)
(* val bad_paren = (1 + 2; *)

(* Valid declaration *)
val after_error_3 = true andalso false;

(* Error 7: duplicate pattern arms (syntactically legal but semantically
   redundant -- exercises the pattern checker) *)
fun dup_patterns 1 = "one"
  | dup_patterns 1 = "also one"
  | dup_patterns _ = "other";

(* Error 8: operator with wrong arity used as value *)
fun misuse_op x = op + x;    (* op + is a binary fn, not unary *)

(* Error 9: empty structure body *)
structure EmptyStruct = struct end;

(* Error 10: functor applied to wrong signature *)
signature S1 = sig val x : int end;
structure M1 : S1 = struct val x = 0 end;

(* Valid complex declaration after errors *)
datatype 'a tree = Leaf | Node of 'a tree * 'a * 'a tree;

fun depth Leaf = 0
  | depth (Node (l, _, r)) = 1 + Int.max (depth l, depth r);

val t = Node (Node (Leaf, 1, Leaf), 2, Node (Leaf, 3, Leaf));
val _ = depth t;

(* Error 11: nonfix used on operator not declared nonfix *)
(* val x = nonfix_op 1 2; *)

(* Error 12: record with missing field *)
(* val bad_record = { x = 1, }; *)

(* Trailing valid code to confirm parser reached end of file *)
val sentinel = 999;
