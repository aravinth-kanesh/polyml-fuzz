(* Local opens and let-open expressions *)

structure Utils =
struct
  fun double x = x * 2
  fun triple x = x * 3
  fun quadruple x = x * 4
end;

(* Local open in let *)
val result1 =
  let
    open Utils
  in
    double 5 + triple 3 + quadruple 2
  end;

structure Math =
struct
  val pi = 3.14159
  fun square x = x * x
  fun sqrt x = Math.sqrt x
end;

structure Physics =
struct
  open Math

  val c = 299792458.0  (* speed of light *)

  fun energy mass = mass * square c

  fun distance velocity time = velocity * time
end;

(* Nested local opens *)
structure A =
struct
  val x = 10
  val y = 20
end;

structure B =
struct
  val z = 30

  structure C =
  struct
    open A
    val sum = x + y + z
  end
end;

structure Combinators =
struct
  fun I x = x
  fun K x y = x
  fun S x y z = x z (y z)

  structure Advanced =
  struct
    open Combinators
    fun B x y z = x (y z)
    fun C x y z = x z y
    fun W x y = x y y
  end
end;

(* Open with qualification *)
structure Result =
struct
  datatype 'a result = Ok of 'a | Error of string

  fun map f (Ok x) = Ok (f x)
    | map f (Error e) = Error e

  fun bind (Ok x) f = f x
    | bind (Error e) f = Error e
end;

local
  open Result
in
  val r1 = Ok 42
  val r2 = map (fn x => x * 2) r1
  val r3 = bind r2 (fn x => Ok (x + 10))
end;
