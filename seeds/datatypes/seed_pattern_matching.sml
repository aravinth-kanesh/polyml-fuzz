(* Complex pattern matching scenarios *)

datatype shape =
    Circle of real
  | Rectangle of real * real
  | Triangle of real * real * real
  | Polygon of (real * real) list;

fun area (Circle r) = 3.14159 * r * r
  | area (Rectangle (w, h)) = w * h
  | area (Triangle (a, b, c)) =
      let val s = (a + b + c) / 2.0
      in Math.sqrt (s * (s - a) * (s - b) * (s - c))
      end
  | area (Polygon _) = 0.0;  (* simplified *)

(* Nested pattern matching *)
datatype color = Red | Green | Blue | RGB of int * int * int;
datatype colored_shape = ColoredShape of shape * color;

fun describe (ColoredShape (Circle r, Red)) = "Red circle"
  | describe (ColoredShape (Circle r, _)) = "Circle"
  | describe (ColoredShape (Rectangle (w, h), RGB (r, g, b))) = "RGB rectangle"
  | describe (ColoredShape (Rectangle (w, h), _)) = "Rectangle"
  | describe (ColoredShape (Triangle _, Red)) = "Red triangle"
  | describe (ColoredShape (Triangle _, Green)) = "Green triangle"
  | describe (ColoredShape (Triangle _, Blue)) = "Blue triangle"
  | describe (ColoredShape (Triangle _, _)) = "Triangle"
  | describe (ColoredShape (Polygon _, _)) = "Polygon";

(* Guards in patterns (if supported) *)
fun classify (Circle r) = if r < 1.0 then "small" else if r < 10.0 then "medium" else "large"
  | classify (Rectangle (w, h)) = if w * h < 10.0 then "small" else "large"
  | classify _ = "unknown";

(* As-patterns *)
datatype tree = Leaf of int | Node of tree * tree;

fun mirror (t as Leaf _) = t
  | mirror (Node (left, right)) = Node (mirror right, mirror left);
