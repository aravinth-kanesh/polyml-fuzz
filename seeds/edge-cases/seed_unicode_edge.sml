(* Unicode and character edge cases *)

(* Standard ASCII *)
val ascii = "Hello, World!";

(* Special characters in strings *)
val special = "!@#$%^&*()_+-=[]{}|;':,.<>?/`~";

(* Escape sequences *)
val newline = "line1\nline2\nline3";
val tab = "col1\tcol2\tcol3";
val quote = "He said \"Hello\"";
val backslash = "C:\\path\\to\\file";
val all_escapes = "\a\b\t\n\v\f\r\\\"";

(* Control characters *)
val null_char = "\^@";
val ctrl_a = "\^A";
val ctrl_z = "\^Z";

(* Character literals *)
val char_a = #"a";
val char_newline = #"\n";
val char_quote = #"\"";

(* Empty-looking but valid *)
val spaces = "     ";
val tabs = "\t\t\t\t";
val newlines = "\n\n\n\n";

(* Unicode in comments *)
(* Greek: α β γ δ ε *)
(* Cyrillic: А Б В Г Д *)
(* Math: ∀ ∃ ∈ ⊆ ∪ ∩ *)
(* Arrows: → ← ↔ ⇒ *)

(* String with only whitespace *)
val only_space = " ";
val only_tab = "\t";
val only_newline = "\n";
val mixed_whitespace = " \t\n ";

(* Very long character sequences *)
val many_a = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
val many_newlines = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";

(* Potentially problematic sequences *)
val looks_like_comment = "(*";
val looks_like_string_end = "\"";
val looks_like_escape = "\\";

(* Hex and special characters *)
val hex_chars = "\x00\x01\x02\xFF";

(* Character ranges *)
val printable = "abc123!@# \t\n";
val upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
val lower = "abcdefghijklmnopqrstuvwxyz";
val digits = "0123456789";

(* Edge case concatenation *)
val concat_empty = "" ^ "" ^ "";
val concat_newlines = "\n" ^ "\n" ^ "\n";

(* String comparison edge cases *)
val eq_empty = ("" = "");
val eq_space = (" " = " ");
val neq_case = ("A" = "a");

(* Char to string *)
val c2s = implode [#"a", #"b", #"c"];
val s2c = explode "abc";
