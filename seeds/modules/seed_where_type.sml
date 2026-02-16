(* Where type specifications *)

signature CONTAINER =
sig
  type 'a t
  val empty : 'a t
  val insert : 'a -> 'a t -> 'a t
  val toList : 'a t -> 'a list
end;

(* Specialize the container type *)
signature INT_CONTAINER = CONTAINER where type 'a t = 'a list;

structure ListContainer : INT_CONTAINER =
struct
  type 'a t = 'a list
  val empty = []
  fun insert x xs = x :: xs
  fun toList xs = xs
end;

signature ORDERED_PAIR =
sig
  type t
  type pair = t * t
  val make : t -> t -> pair
  val first : pair -> t
  val second : pair -> t
end;

signature INT_PAIR = ORDERED_PAIR where type t = int;

structure IntPair : INT_PAIR =
struct
  type t = int
  type pair = t * t
  fun make x y = (x, y)
  fun first (x, _) = x
  fun second (_, y) = y
end;

(* Multiple where type constraints *)
signature CONVERTER =
sig
  type input
  type output
  val convert : input -> output
end;

signature STRING_TO_INT = CONVERTER
  where type input = string
  where type output = int;

structure StringToInt : STRING_TO_INT =
struct
  type input = string
  type output = int
  fun convert s = case Int.fromString s of
                    SOME n => n
                  | NONE => 0
end;
