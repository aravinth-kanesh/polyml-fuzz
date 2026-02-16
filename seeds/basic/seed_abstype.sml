(* Abstract types with abstype *)

abstype counter = Counter of int ref
with
  fun new () = Counter (ref 0)
  fun inc (Counter r) = r := !r + 1
  fun dec (Counter r) = r := !r - 1
  fun value (Counter r) = !r
  fun reset (Counter r) = r := 0
end;

val c1 = new ();
val _ = inc c1;
val _ = inc c1;
val _ = inc c1;
val v1 = value c1;
val _ = dec c1;
val v2 = value c1;

(* Abstract type for stack *)
abstype 'a stack = Stack of 'a list ref
with
  fun empty () = Stack (ref [])
  fun push x (Stack r) = r := x :: !r
  fun pop (Stack r) =
    case !r of
        [] => NONE
      | (x :: xs) => (r := xs; SOME x)
  fun top (Stack r) =
    case !r of
        [] => NONE
      | (x :: _) => SOME x
  fun size (Stack r) = length (!r)
  fun isEmpty (Stack r) = null (!r)
end;

val s = empty ();
val _ = push 1 s;
val _ = push 2 s;
val _ = push 3 s;
val sz = size s;
val t = top s;
val p1 = pop s;
val p2 = pop s;

(* Abstract type for queue *)
abstype 'a queue = Queue of ('a list * 'a list) ref
with
  fun empty_queue () = Queue (ref ([], []))

  fun enqueue x (Queue r) =
    let val (front, back) = !r
    in r := (front, x :: back)
    end

  fun dequeue (Queue r) =
    case !r of
        ([], []) => NONE
      | (x :: front, back) => (r := (front, back); SOME x)
      | ([], back) =>
          case rev back of
              [] => NONE
            | (x :: front) => (r := (front, []); SOME x)

  fun queue_size (Queue r) =
    let val (front, back) = !r
    in length front + length back
    end
end;

val q = empty_queue ();
val _ = enqueue 1 q;
val _ = enqueue 2 q;
val _ = enqueue 3 q;
val qs = queue_size q;
val d1 = dequeue q;
val d2 = dequeue q;
