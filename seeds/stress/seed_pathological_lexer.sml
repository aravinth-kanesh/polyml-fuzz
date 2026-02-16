(* Pathological cases for lexer *)

(* Many consecutive operators *)
val ops = 1+2-3*4 div 5 mod 6;

(* No whitespace between tokens *)
val nospace=let val x=1 in x+2*3 end;

(* Maximum whitespace *)
val   lots_of_spaces   =   1   +   2   +   3   ;

(* Mixed tabs and spaces *)
val	mixed	=	let	val	x	=	1	in	x	+	2	end	;

(* Long sequence of identifiers *)
val a b c d e f g h i j k l m n o p q r s t u v w x y z = z;

(* Identifiers that look like keywords *)
val letter = 1;
val letter_a = 2;
val in_ = 3;
val end_ = 4;
val if_ = 5;
val then_ = 6;
val else_ = 7;
val let_ = 8;
val fun_ = 9;
val val_ = 10;

(* Numbers followed immediately by identifiers *)
val x = 123abc;  (* Should be: 123 followed by abc *)
val y = 456xyz789;

(* String edge cases *)
val empty_string = "";
val quote_string = "\"";
val backslash_string = "\\";
val all_chars = "!@#$%^&*()_+-=[]{}|;:',.<>?/`~";

(* Comments in weird places *)
val(* comment *)x(* comment *)=(* comment *)1(* comment *);

(* Operator followed by comment *)
val z = 1 + (* in middle *) 2;

(* Very long line *)
val long_line = 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12 + 13 + 14 + 15 + 16 + 17 + 18 + 19 + 20 + 21 + 22 + 23 + 24 + 25 + 26 + 27 + 28 + 29 + 30 + 31 + 32 + 33 + 34 + 35 + 36 + 37 + 38 + 39 + 40;

(* Consecutive underscores *)
val __ = 1;
val ___ = 2;
val ____ = 3;
val __________ = 4;

(* Parentheses stress *)
val p = ((((((((((1)))))))) + ((((2))))));

(* Many semicolons *)
val s1 = 1; val s2 = 2; val s3 = 3; val s4 = 4; val s5 = 5;

(* Unicode-like identifiers (if supported) *)
val αβγδε = 123;
val АБВГД = 456;

(* Zero-width or unusual characters *)
val ​x = 1;  (* May contain zero-width space *)

(* Identifiers starting with special chars *)
val '_special = 100;
val 'a = 200;

(* Maximum nesting of delimiters *)
val nest = [[[[[[[[[[1]]]]]]]]]];
val nest_tuple = ((((((((((1, 2)))))))));

(* Case where keywords could be confused *)
val andalso_test = true andalso false;
val orelse_test = true orelse false;
val andalsothen = 1;  (* identifier, not keyword *)

(* Escaped newlines in strings *)
val multiline = "line1\
                \line2\
                \line3";
