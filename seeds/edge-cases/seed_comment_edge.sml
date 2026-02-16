(* Comment edge cases *)

(* Empty comment *)
(**)

(* Minimal comment *)
(* *)

(* Comment with just one char *)
(*a*)

(* Comment next to code *)
val x(*comment*)=(*comment*)1(*comment*);

(* Comment in string *)
val s = "(* not a comment *)";

(* String in comment *)
(* This comment has a "string" inside *)

(* Nested comment symbols *)
(* Outer (* Inner *) Outer *)

(* Multiple nesting levels *)
(* L1 (* L2 (* L3 (* L4 (* L5 *) L4 *) L3 *) L2 *) L1 *)

(* Unbalanced-looking but valid *)
(* This has (* inside but closes fine *)
(* This has *) inside the comment which is fine *)

(* Comment with star at end *)
(* This comment ends with a star * *)

(* Comment with paren at end *)
(* This comment ends with a paren ( *)

(* Many stars *)
(***************************************************)

(* Many parens *)
(* ((((((((((((((((((((((( ))))))))))))))))))))))) *)

(* Mixed delimiters *)
(* { [ ( < > ) ] } *)

(* Comment-like sequences in comments *)
(* This has (** and **) and *(* inside *)

(* Consecutive comments *)
(* First *)(* Second *)(* Third *)

(* Comments on every line *)
(* Line 1 *)
(* Line 2 *)
(* Line 3 *)
val y = 1; (* After val *)

(* Comment at EOF *)
(* This is the last comment *)

(* Potentially confusing sequences *)
(* This has (* and later *) but not nested *)
(* This has **) which looks like end *)
(* This has (** which looks like nested start *)

(* Comments with code-like content *)
(*
fun f x = x + 1;
val result = f 42;
datatype t = A | B;
*)

(* Comment splitting a token *)
val long_(*comment*)identifier = 5;

(* Comments around operators *)
val sum = 1 (*+*) + (*+*) 2;

(* Very long comment *)
(*
This is a very long comment that goes on and on and on and on and on and on
and on and on and on and on and on and on and on and on and on and on and on
and on and on and on and on and on and on and on and on and on and on and on.
*)

(* Comment with nested structure *)
(*
  This is indented
    This is more indented
      This is even more indented
    Back one level
  Back to first level
*)

(* Final comment at the very end of the file *)
(* EOF *)
