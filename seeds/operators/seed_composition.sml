(* Operator composition and combinators *)

(* Function composition operators *)
infixr 9 o;
infixr 9 oo;
infixl 1 |>;
infixr 1 <|;

fun (f o g) x = f (g x);
fun (f oo g) x = f (g x);
fun x |> f = f x;
fun f <| x = f x;

fun double x = x * 2;
fun inc x = x + 1;
fun square x = x * x;

(* Right-associative composition *)
val f1 = double o inc o square;
val r1 = f1 5;  (* double(inc(square(5))) = double(inc(25)) = double(26) = 52 *)

(* Pipeline operators *)
val r2 = 5 |> square |> inc |> double;  (* Left-to-right: ((5^2)+1)*2 = 52 *)
val r3 = double <| inc <| square <| 5;  (* Right-to-left *)

(* Monadic bind operators *)
infixl 1 >>=;
infixr 1 =<<;

fun (SOME x) >>= f = f x
  | NONE >>= f = NONE;

fun f =<< mx = mx >>= f;

fun safe_div (_, 0) = NONE
  | safe_div (x, y) = SOME (x div y);

fun safe_inc x = SOME (x + 1);

val r4 = SOME 10 >>= safe_inc >>= (fn x => safe_div (x, 2));
val r5 = safe_div (100, 5) >>= safe_inc >>= safe_inc;

(* Applicative operators *)
infixl 4 <*>;
infixl 4 <$>;

fun (SOME f) <*> (SOME x) = SOME (f x)
  | _ <*> _ = NONE;

fun f <$> x = SOME f <*> x;

val r6 = (fn x => x + 1) <$> SOME 5;
val r7 = SOME (fn x => x * 2) <*> SOME 10;

(* Alternative operator *)
infixl 3 <|>;

fun (SOME x) <|> _ = SOME x
  | NONE <|> y = y;

val r8 = NONE <|> NONE <|> SOME 42 <|> SOME 100;

(* Combining multiple operators *)
val r9 = (double o inc) <$> SOME 5;
val r10 = SOME 10 >>= safe_inc >>= (fn x => SOME (double x));

(* Operator sections (if supported) *)
infixl 6 ++;
fun a ++ b = a + b;

val add5 = (op ++) (5, 3);  (* Call as function *)

(* Dollar operator for avoiding parentheses *)
infixr 0 $;
fun f $ x = f x;

val r11 = double $ inc $ square 5;
val r12 = double $ double $ double 2;

(* Compose with pipeline *)
val r13 = 5 |> (double o inc o square);
val r14 = (double o inc o square) <| 5;
