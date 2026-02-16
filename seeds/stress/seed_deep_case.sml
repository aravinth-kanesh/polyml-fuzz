(* Deeply nested case expressions *)

datatype nested =
    L1 of nested
  | L2 of nested * nested
  | L3 of nested * nested * nested
  | Leaf of int;

fun process n =
  case n of
      L1 (L1 (L1 (L1 (L1 (Leaf x))))) => x
    | L1 (L1 (L1 (L1 (L2 (Leaf x, Leaf y))))) => x + y
    | L1 (L1 (L1 (L2 (Leaf a, Leaf b)))) => a + b
    | L1 (L1 (L2 (Leaf a, Leaf b))) => a + b
    | L1 (L2 (Leaf a, Leaf b)) => a + b
    | L2 (L1 (Leaf a), L1 (Leaf b)) => a + b
    | L2 (L2 (Leaf a, Leaf b), L2 (Leaf c, Leaf d)) => a + b + c + d
    | L3 (Leaf a, Leaf b, Leaf c) => a + b + c
    | L3 (L1 (Leaf a), L1 (Leaf b), L1 (Leaf c)) => a + b + c
    | L3 (L2 (Leaf a, Leaf b), L2 (Leaf c, Leaf d), L2 (Leaf e, Leaf f)) => a + b + c + d + e + f
    | Leaf x => x
    | _ => 0;

(* Nested case within case *)
fun nested_case x y =
  case x of
      0 => (case y of
                0 => (case x + y of
                          0 => 0
                        | 1 => 1
                        | _ => (case y - x of
                                    0 => 10
                                  | _ => 20))
              | 1 => 100
              | _ => (case x * y of
                          0 => 200
                        | _ => 300))
    | 1 => (case y of
                0 => (case x - y of
                          1 => 400
                        | _ => 500)
              | _ => 600)
    | _ => (case y of
                0 => 700
              | _ => (case x + y of
                          0 => 800
                        | _ => 900));

(* Very wide case expression *)
fun wide_case n =
  case n of
      0 => 0
    | 1 => 1
    | 2 => 2
    | 3 => 3
    | 4 => 4
    | 5 => 5
    | 6 => 6
    | 7 => 7
    | 8 => 8
    | 9 => 9
    | 10 => 10
    | 11 => 11
    | 12 => 12
    | 13 => 13
    | 14 => 14
    | 15 => 15
    | 16 => 16
    | 17 => 17
    | 18 => 18
    | 19 => 19
    | 20 => 20
    | 21 => 21
    | 22 => 22
    | 23 => 23
    | 24 => 24
    | 25 => 25
    | 26 => 26
    | 27 => 27
    | 28 => 28
    | 29 => 29
    | 30 => 30
    | _ => ~1;
