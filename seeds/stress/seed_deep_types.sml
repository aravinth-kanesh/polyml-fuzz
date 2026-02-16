(* Deeply nested and complex type expressions *)

type level1 = int;
type level2 = level1 * level1;
type level3 = level2 * level2;
type level4 = level3 * level3;
type level5 = level4 * level4;
type level6 = level5 * level5;
type level7 = level6 * level6;

(* Function types with deep nesting *)
type func1 = int -> int;
type func2 = func1 -> func1;
type func3 = func2 -> func2;
type func4 = func3 -> func3;
type func5 = func4 -> func4;
type func6 = func5 -> func5;

(* Record types with many fields and nested structure *)
type point = {x: real, y: real};
type rect = {tl: point, br: point};
type shape = {id: int, bounds: rect, color: int * int * int};
type layer = {name: string, shapes: shape list, visible: bool};
type canvas = {width: int, height: int, layers: layer list};
type document = {
    filename: string,
    canvas: canvas,
    metadata: {author: string, created: int, modified: int}
};

(* Polymorphic types with constraints *)
type 'a option_list = 'a option list;
type ('a, 'b) either_list = ('a, 'b) either list
and ('a, 'b) either = Left of 'a | Right of 'b;

type ('a, 'b, 'c) triple = 'a * 'b * 'c;
type ('a, 'b, 'c, 'd) quad = ('a, 'b, 'c) triple * 'd;
type ('a, 'b, 'c, 'd, 'e) quint = ('a, 'b, 'c, 'd) quad * 'e;

(* Very long type expression *)
type complex = (int * (string * (bool * (real * (int * (string * (bool * real)))))));

(* Type abbreviations with deep indirection *)
type t1 = int list;
type t2 = t1 list;
type t3 = t2 list;
type t4 = t3 list;
type t5 = t4 list;
type t6 = t5 list;
type t7 = t6 list;
type t8 = t7 list;

(* Mutually recursive types with complexity *)
datatype tree = Leaf of int | Node of int * forest
and forest = Empty | Trees of tree list;

datatype expr =
    Num of int
  | Var of string
  | Binary of binop * expr * expr
  | Unary of unop * expr
  | Let of binding list * expr
  | Lambda of pattern * expr
  | Apply of expr * expr
and binop = Add | Sub | Mul | Div | Mod
and unop = Neg | Not
and pattern = VarPat of string | TuplePat of pattern list | ConsPat of pattern * pattern
and binding = ValBind of pattern * expr | FunBind of string * pattern * expr;

(* Function type with many parameters via currying *)
type many_params = int -> int -> int -> int -> int -> int -> int -> int -> int -> int;

(* Nested datatype constructors *)
datatype deep =
    D1 of (int * (string * (bool * real)))
  | D2 of ((int * int) * ((string * string) * ((bool * bool) * (real * real))))
  | D3 of (int * int * int) * (string * string * string) * (bool * bool * bool);
