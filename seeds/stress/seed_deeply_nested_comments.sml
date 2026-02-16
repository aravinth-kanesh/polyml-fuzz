(* Deeply nested comments to stress comment handling *)

(* Level 1 (* Level 2 (* Level 3 (* Level 4 (* Level 5 (* Level 6 (* Level 7 (* Level 8 (* Level 9 (* Level 10 *) *) *) *) *) *) *) *) *) *)

val x = 1;

(* Even deeper nesting *)
(* A (* B (* C (* D (* E (* F (* G (* H (* I (* J (* K (* L (* M (* N (* O (* P *) *) *) *) *) *) *) *) *) *) *) *) *) *) *) *)

val y = 2;

(* Comments with code inside *)
(* This is commented out:
   (* And this is nested:
      (* And this is even more nested:
         fun f x = x + 1;
         val z = 42;
         (* And another level:
            datatype t = A | B | C;
            (* And yet another:
               structure S = struct val v = 10 end;
               (* Final level:
                  val final = 100;
               *)
            *)
         *)
      *)
   *)
*)

val a = 3;

(* Pathological comment nesting *)
(*
  (*
    (*
      (*
        (*
          (*
            (*
              (*
                (*
                  (*
                    (* This is 11 levels deep *)
                  *)
                *)
              *)
            *)
          *)
        *)
      *)
    *)
  *)
*)

val b = 4;

(* Interleaved code and comments *)
val c1 = (* nested (* comment *) here *) 10;
val c2 = 20 (* another (* nested (* deeply (* more *) *) *) comment *);

(* Unterminated-looking but actually valid *)
(* This comment has a (* inside but is properly closed *)

(* Multiple (* nested (* blocks (* in (* sequence *) *) *) *) *)
(* And (* another (* set (* of (* nested (* comments *) *) *) *) *) *)
(* Yet (* more (* nesting (* to (* stress (* the (* parser *) *) *) *) *) *) *)

val result = x + y + a + b + c1 + c2;
