(* Record types and field access *)

type point = {x: real, y: real};
type rect = {top_left: point, width: real, height: real};

val origin = {x = 0.0, y = 0.0};
val p1 = {x = 3.0, y = 4.0};

fun distance {x = x1, y = y1} {x = x2, y = y2} =
    let val dx = x2 - x1
        val dy = y2 - y1
    in Math.sqrt (dx * dx + dy * dy)
    end;

fun translate {x, y} dx dy = {x = x + dx, y = y + dy};

(* Record with more fields *)
type person = {
    name: string,
    age: int,
    height: real,
    weight: real,
    employed: bool
};

val alice = {
    name = "Alice",
    age = 30,
    height = 165.0,
    weight = 60.0,
    employed = true
};

fun get_bmi {height, weight, ...} = weight / ((height / 100.0) * (height / 100.0));

(* Nested records *)
type address = {street: string, city: string, zip: int};
type employee = {name: string, id: int, addr: address};

val john = {
    name = "John",
    id = 12345,
    addr = {street = "123 Main St", city = "Boston", zip = 02101}
};

fun get_city {addr = {city, ...}, ...} = city;

(* Record update pattern *)
fun birthday {name, age, height, weight, employed} =
    {name = name, age = age + 1, height = height, weight = weight, employed = employed};
