(* Deep function application chains to stress the parser's call chain reduction *)

fun f0 x = x + 1;
fun f1 x = f0 (f0 x);
fun f2 x = f1 (f1 x);
fun f3 x = f2 (f2 x);
fun f4 x = f3 (f3 x);
fun f5 x = f4 (f4 x);
fun f6 x = f5 (f5 x);
fun f7 x = f6 (f6 x);

(* Deeply chained single-argument applications *)
val r1 = f7 (f6 (f5 (f4 (f3 (f2 (f1 (f0 0)))))));

(* Tupled argument chains *)
fun g0 (x, y) = x + y;
fun g1 (x, y) = g0 (g0 (x, y), g0 (y, x));
fun g2 (x, y) = g1 (g1 (x, y), g1 (y, x));
fun g3 (x, y) = g2 (g2 (x, y), g2 (y, x));

val r2 = g3 (1, 2);

(* Higher-order application chains -- exercises closure creation *)
fun apply f x = f x;
fun compose f g x = f (g x);

val inc = fn x => x + 1;
val double = fn x => x * 2;

val pipeline =
    compose inc
   (compose double
   (compose inc
   (compose double
   (compose inc
   (compose double inc)))));

val r3 = pipeline 0;

(* Curried application tower *)
fun add a b = a + b;
fun mul a b = a * b;

val tower =
    add 1
        (mul 2
             (add 3
                  (mul 4
                       (add 5
                            (mul 6
                                 (add 7 8))))));

val r4 = tower;

(* Operator section chains via lambda *)
val ops = List.foldl (fn (f, acc) => f acc) 0
    [fn x => x + 1,
     fn x => x * 3,
     fn x => x - 2,
     fn x => x + 10,
     fn x => x * x,
     fn x => x - 1,
     fn x => x + 5];

val _ = print (Int.toString r1 ^ "\n");
val _ = print (Int.toString r2 ^ "\n");
val _ = print (Int.toString r3 ^ "\n");
val _ = print (Int.toString r4 ^ "\n");
val _ = print (Int.toString ops ^ "\n");
