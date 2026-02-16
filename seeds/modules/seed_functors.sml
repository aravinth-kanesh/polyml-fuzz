(* Functors - parameterized modules *)

signature ORDERED =
sig
  type t
  val compare : t * t -> order
end;

signature SET =
sig
  type elem
  type set
  val empty : set
  val insert : elem * set -> set
  val member : elem * set -> bool
end;

functor SetFn (Ord : ORDERED) : SET =
struct
  type elem = Ord.t
  type set = elem list

  val empty = []

  fun insert (x, []) = [x]
    | insert (x, y :: ys) =
        case Ord.compare (x, y) of
            LESS => x :: y :: ys
          | EQUAL => y :: ys
          | GREATER => y :: insert (x, ys)

  fun member (x, []) = false
    | member (x, y :: ys) =
        case Ord.compare (x, y) of
            LESS => false
          | EQUAL => true
          | GREATER => member (x, ys)
end;

structure IntOrd : ORDERED =
struct
  type t = int
  fun compare (x, y) =
    if x < y then LESS
    else if x > y then GREATER
    else EQUAL
end;

structure IntSet = SetFn(IntOrd);

val s = IntSet.empty;
val s = IntSet.insert (5, s);
val s = IntSet.insert (3, s);
val s = IntSet.insert (7, s);
val has5 = IntSet.member (5, s);
val has6 = IntSet.member (6, s);
