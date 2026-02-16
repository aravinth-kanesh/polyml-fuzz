(* Very long string literals *)

val short_string = "This is a normal string";

val long_string = "This is a very long string that goes on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on";

val string_with_escapes = "This string has many escape sequences:\n\n\n\n\n\n\n\n\n\n\t\t\t\t\t\t\t\t\t\t\"\"\"\"\"\"\"\"\"\"\\\\\\\\\\\\\\\\\\\\ and more and more and more";

val multiline_string = "This is a \
                       \multiline \
                       \string that \
                       \spans many \
                       \lines with \
                       \continuation \
                       \characters \
                       \everywhere";

val string_with_unicode = "Unicode test: \u0041\u0042\u0043 and more \u03B1\u03B2\u03B3";

(* String concatenation stress *)
val concat1 = "a" ^ "b" ^ "c" ^ "d" ^ "e" ^ "f" ^ "g" ^ "h" ^ "i" ^ "j" ^ "k" ^ "l" ^ "m" ^ "n" ^ "o" ^ "p" ^ "q" ^ "r" ^ "s" ^ "t" ^ "u" ^ "v" ^ "w" ^ "x" ^ "y" ^ "z";

val concat2 = "Lorem" ^ " " ^ "ipsum" ^ " " ^ "dolor" ^ " " ^ "sit" ^ " " ^ "amet" ^ " " ^ "consectetur" ^ " " ^ "adipiscing" ^ " " ^ "elit" ^ " " ^ "sed" ^ " " ^ "do" ^ " " ^ "eiusmod" ^ " " ^ "tempor" ^ " " ^ "incididunt";

(* Very long string literal (1000+ characters) *)
val very_long = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";

(* String with all escape sequences *)
val all_escapes = "\a\b\t\n\v\f\r\\\"\' and more";

(* Strings in expressions *)
val expr1 = if "test" = "test" then "equal" else "not equal";
val expr2 = case "hello" of "hello" => 1 | "world" => 2 | _ => 0;
