(* Signature refinement and specialization *)

signature COLLECTION =
sig
  type 'a t
  val empty : 'a t
  val size : 'a t -> int
  val member : ''a -> ''a t -> bool
end;

signature ORDERED_COLLECTION =
sig
  include COLLECTION
  val min : 'a t -> 'a option
  val max : 'a t -> 'a option
end;

signature MUTABLE_COLLECTION =
sig
  include COLLECTION
  val add : 'a -> 'a t -> unit
  val remove : ''a -> ''a t -> unit
  val clear : 'a t -> unit
end;

(* Implementation *)
structure ListCollection : COLLECTION =
struct
  type 'a t = 'a list ref
  fun empty () = ref []
  fun size r = length (!r)
  fun member x r = List.exists (fn y => x = y) (!r)
end;

(* Signature ascription with additional constraints *)
signature FINITE_MAP =
sig
  type key
  type 'a map
  val empty : 'a map
  val insert : key * 'a -> 'a map -> 'a map
  val lookup : key -> 'a map -> 'a option
  val keys : 'a map -> key list
  val values : 'a map -> 'a list
end;

signature ORDERED_MAP =
sig
  include FINITE_MAP
  val min_key : 'a map -> key option
  val max_key : 'a map -> key option
  val range : key * key -> 'a map -> (key * 'a) list
end;

structure IntMap : FINITE_MAP =
struct
  type key = int
  type 'a map = (key * 'a) list
  val empty = []
  fun insert (k, v) m = (k, v) :: m
  fun lookup k [] = NONE
    | lookup k ((k', v) :: rest) =
        if k = k' then SOME v else lookup k rest
  fun keys m = List.map #1 m
  fun values m = List.map #2 m
end;

(* Gradual refinement *)
signature BASE_CONTAINER =
sig
  type elem
  type container
end;

signature CONTAINER_OPS =
sig
  include BASE_CONTAINER
  val empty : container
  val insert : elem -> container -> container
end;

signature FULL_CONTAINER =
sig
  include CONTAINER_OPS
  val delete : elem -> container -> container
  val size : container -> int
  val toList : container -> elem list
end;
