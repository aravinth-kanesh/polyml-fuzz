(* String operations *)

val hello = "Hello, World!";
val empty = "";
val newline = "Line 1\nLine 2\nLine 3";
val tab = "Col1\tCol2\tCol3";

fun concat (s1, s2) = s1 ^ s2;

val greeting = concat ("Hello, ", "Poly/ML");
val long_string = "This is a very long string that contains multiple words and should test string handling in the lexer and parser components";

val escaped = "Quote: \" Backslash: \\ Newline: \n";
val multiline = "Line 1\n\
                \Line 2\n\
                \Line 3";
