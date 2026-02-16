(* Complex functor with multiple parameters *)

signature ORDERED =
sig
  type t
  val compare : t * t -> order
end;

signature SHOWABLE =
sig
  type t
  val show : t -> string
end;

signature BINARY_TREE =
sig
  type elem
  type tree
  val empty : tree
  val insert : elem -> tree -> tree
  val member : elem -> tree -> bool
  val toList : tree -> elem list
  val toString : tree -> string
end;

functor BinaryTreeFn (structure Ord : ORDERED
                      structure Show : SHOWABLE
                      sharing type Ord.t = Show.t) : BINARY_TREE =
struct
  type elem = Ord.t
  datatype tree = Leaf | Node of elem * tree * tree

  val empty = Leaf

  fun insert x Leaf = Node (x, Leaf, Leaf)
    | insert x (Node (y, left, right)) =
        case Ord.compare (x, y) of
            LESS => Node (y, insert x left, right)
          | EQUAL => Node (y, left, right)
          | GREATER => Node (y, left, insert x right)

  fun member x Leaf = false
    | member x (Node (y, left, right)) =
        case Ord.compare (x, y) of
            LESS => member x left
          | EQUAL => true
          | GREATER => member x right

  fun toList Leaf = []
    | toList (Node (x, left, right)) = toList left @ [x] @ toList right

  fun toString Leaf = "Leaf"
    | toString (Node (x, left, right)) =
        "Node(" ^ Show.show x ^ ", " ^ toString left ^ ", " ^ toString right ^ ")"
end;

structure IntOrd : ORDERED =
struct
  type t = int
  fun compare (x, y) =
    if x < y then LESS
    else if x > y then GREATER
    else EQUAL
end;

structure IntShow : SHOWABLE =
struct
  type t = int
  fun show n = Int.toString n
end;

structure IntTree = BinaryTreeFn(structure Ord = IntOrd
                                  structure Show = IntShow);

val t = IntTree.empty;
val t = IntTree.insert 5 t;
val t = IntTree.insert 3 t;
val t = IntTree.insert 7 t;
val t = IntTree.insert 1 t;
val xs = IntTree.toList t;
val str = IntTree.toString t;
