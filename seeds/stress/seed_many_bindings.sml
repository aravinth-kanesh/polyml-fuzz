(* Many top-level bindings to stress symbol table *)

val v1 = 1;
val v2 = 2;
val v3 = 3;
val v4 = 4;
val v5 = 5;
val v6 = 6;
val v7 = 7;
val v8 = 8;
val v9 = 9;
val v10 = 10;
val v11 = 11;
val v12 = 12;
val v13 = 13;
val v14 = 14;
val v15 = 15;
val v16 = 16;
val v17 = 17;
val v18 = 18;
val v19 = 19;
val v20 = 20;

fun f1 x = x + 1;
fun f2 x = x + 2;
fun f3 x = x + 3;
fun f4 x = x + 4;
fun f5 x = x + 5;
fun f6 x = x + 6;
fun f7 x = x + 7;
fun f8 x = x + 8;
fun f9 x = x + 9;
fun f10 x = x + 10;
fun f11 x = x + 11;
fun f12 x = x + 12;
fun f13 x = x + 13;
fun f14 x = x + 14;
fun f15 x = x + 15;
fun f16 x = x + 16;
fun f17 x = x + 17;
fun f18 x = x + 18;
fun f19 x = x + 19;
fun f20 x = x + 20;

datatype t1 = C1 of int;
datatype t2 = C2 of int;
datatype t3 = C3 of int;
datatype t4 = C4 of int;
datatype t5 = C5 of int;
datatype t6 = C6 of int;
datatype t7 = C7 of int;
datatype t8 = C8 of int;
datatype t9 = C9 of int;
datatype t10 = C10 of int;

type alias1 = int;
type alias2 = string;
type alias3 = bool;
type alias4 = real;
type alias5 = int * int;
type alias6 = string * string;
type alias7 = int list;
type alias8 = string list;
type alias9 = int * string;
type alias10 = bool * real;

structure S1 = struct val x = 1 end;
structure S2 = struct val x = 2 end;
structure S3 = struct val x = 3 end;
structure S4 = struct val x = 4 end;
structure S5 = struct val x = 5 end;
structure S6 = struct val x = 6 end;
structure S7 = struct val x = 7 end;
structure S8 = struct val x = 8 end;
structure S9 = struct val x = 9 end;
structure S10 = struct val x = 10 end;

signature SIG1 = sig val x : int end;
signature SIG2 = sig val x : int end;
signature SIG3 = sig val x : int end;
signature SIG4 = sig val x : int end;
signature SIG5 = sig val x : int end;

infix 6 op1;
infix 6 op2;
infix 6 op3;
infix 6 op4;
infix 6 op5;

fun a op1 b = a + b;
fun a op2 b = a - b;
fun a op3 b = a * b;
fun a op4 b = a div b;
fun a op5 b = a mod b;

val r1 = 10 op1 5;
val r2 = 10 op2 5;
val r3 = 10 op3 5;
val r4 = 10 op4 5;
val r5 = 10 op5 5;

exception E1;
exception E2 of int;
exception E3 of string;
exception E4 of int * int;
exception E5 of string * bool;

val result = v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 +
             v11 + v12 + v13 + v14 + v15 + v16 + v17 + v18 + v19 + v20;
