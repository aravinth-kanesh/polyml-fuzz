(* Type system edge cases *)

(* Unit type *)
val u1 = ();
val u2 : unit = ();

fun returns_unit () = ();
fun takes_unit (x : unit) = 5;

val r1 = takes_unit ();

(* Empty tuple ambiguity *)
val empty = ();  (* unit *)
(* val single = (1,);  (* Is this valid? *) *)

(* Very long tuple *)
val long_tuple = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);

(* Nested tuple types *)
type t1 = int * int;
type t2 = t1 * t1;
type t3 = t2 * t2;
type t4 = t3 * t3;

(* Type variable shadowing *)
type 'a t = 'a * 'a;
type 'a list = 'a t;  (* Shadows built-in list *)

(* Equality type variables *)
fun eq (x: ''a) y = x = y;

val e1 = eq 5 5;
val e2 = eq "hi" "hi";
(* val e3 = eq (fn x => x) (fn x => x);  (* Would fail: not eq type *) *)

(* Very polymorphic *)
fun id1 x = x;
fun id2 (x: 'a) : 'a = x;
fun id3 x : 'a = x;

(* Type constraints *)
val constrained = (5 : int);
val double_constrained = ((5 : int) : int);

(* Recursive types *)
datatype 'a tree = Leaf | Node of 'a * 'a tree * 'a tree;

(* Mutually recursive with indirection *)
datatype t1 = T1 of t2
and t2 = T2 of t1 | End;

(* Phantom types *)
datatype 'a phantom = Phantom of int;

val p1 : int phantom = Phantom 5;
val p2 : string phantom = Phantom 5;

(* Function types with many arrows *)
type f1 = int -> int;
type f2 = int -> int -> int;
type f3 = int -> int -> int -> int;
type f4 = int -> int -> int -> int -> int;

(* Type abbreviations that look circular *)
type t = int;
type t = string;  (* Shadows previous *)

(* Record type edge cases *)
type empty_record = {};  (* May be invalid *)
type single_field = {x: int};
type duplicate_fields = {x: int, x: string};  (* Should be error *)

(* Very long record *)
type long_record = {
  f1: int, f2: int, f3: int, f4: int, f5: int,
  f6: int, f7: int, f8: int, f9: int, f10: int,
  f11: int, f12: int, f13: int, f14: int, f15: int
};

(* Datatype with no constructors *)
(* datatype empty = ;  (* Would be invalid *) *)

(* Datatype with same constructor names *)
datatype d1 = A | B | C;
datatype d2 = A | B | C;  (* Shadows d1 constructors *)

(* Type with same name as value *)
val int = 5;  (* Shadows type int? *)
type string = int;  (* Shadows type string *)
