{
open Lexing

let buff = Out.create_buff ()
;;

let put s =
  Out.put buff s
and put_char c =
  Out.put_char buff c
;;

let nesting = ref 0
;;

exception Over of string * string
;;

exception Fini
;;

}
rule entry = parse
  "\\\""
    {put "\\\"" ; entry lexbuf}
| "\"!"
    {put_char '!' ; entry lexbuf}
| "\"@"
    {put_char '@' ; entry lexbuf}
| '{'
    {put_char '{' ; nesting := !nesting + 1 ; entry lexbuf}
| '}'
    {if !nesting > 1 then begin
      nesting := !nesting-1 ; put_char '}' ; entry lexbuf
    end else begin
      nesting  := 0 ;
      raise (Over (Out.to_string buff,""))
    end}
| '!'
    {Out.to_string buff,""}
| '@'
    {let name = Out.to_string buff in
    try
      let pretty,_ = entry lexbuf in
      name,pretty
    with Over (s,_) -> raise (Over (name,s))}
| _
   {let lxm = lexeme_char lexbuf 0 in put_char lxm ; entry lexbuf}

and skip_par = parse [' ''\n']* '{' {nesting := 1}

and idx = parse
  "\\indexentry"
     {let x = Save.arg lexbuf in
     let _ = Save.arg lexbuf in
     x}
| eof {raise Fini}
| _ {idx lexbuf}

