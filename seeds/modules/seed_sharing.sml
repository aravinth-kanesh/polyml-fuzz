(* Sharing constraints and type sharing *)

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
  val insert : elem -> set -> set
  val member : elem -> set -> bool
end;

signature MAP =
sig
  type key
  type 'a map
  val empty : 'a map
  val insert : key * 'a -> 'a map -> 'a map
  val lookup : key -> 'a map -> 'a option
end;

(* Sharing constraint *)
signature COLLECTION =
sig
  structure Key : ORDERED
  structure S : SET
  structure M : MAP
  sharing type S.elem = Key.t
  sharing type M.key = Key.t
end;

structure IntKey : ORDERED =
struct
  type t = int
  fun compare (x, y) =
    if x < y then LESS
    else if x > y then GREATER
    else EQUAL
end;

structure IntListSet : SET =
struct
  type elem = int
  type set = elem list
  val empty = []
  fun insert x xs = x :: xs
  fun member x [] = false
    | member x (y :: ys) = x = y orelse member x ys
end;

structure IntListMap : MAP =
struct
  type key = int
  type 'a map = (key * 'a) list
  val empty = []
  fun insert (k, v) xs = (k, v) :: xs
  fun lookup k [] = NONE
    | lookup k ((k', v) :: rest) = if k = k' then SOME v else lookup k rest
end;

structure IntCollection : COLLECTION =
struct
  structure Key = IntKey
  structure S = IntListSet
  structure M = IntListMap
end;
