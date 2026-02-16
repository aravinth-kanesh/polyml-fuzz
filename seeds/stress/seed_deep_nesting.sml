(* Deep nesting to stress parser recursion *)

fun deeply_nested 0 = 0
  | deeply_nested n =
      let
        val x = deeply_nested (n - 1)
      in
        if x > 0 then
          if x > 10 then
            if x > 20 then
              if x > 30 then x
              else x + 1
            else x + 2
          else x + 3
        else x + 4
      end;

(* Nested comments *)
(* Level 1 (* Level 2 (* Level 3 (* Level 4 *) back to 3 *) back to 2 *) back to 1 *)

(* Nested let expressions *)
let
  val a = let
    val b = let
      val c = let
        val d = 42
      in d + 1
      end
    in c + 2
    end
  in b + 3
  end
in
  a + 4
end;
