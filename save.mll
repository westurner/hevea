(***********************************************************************)
(*                                                                     *)
(*                          HEVEA                                      *)
(*                                                                     *)
(*  Luc Maranget, projet PARA, INRIA Rocquencourt                      *)
(*                                                                     *)
(*  Copyright 1998 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(***********************************************************************)

{
open Lexing

let header = "$Id: save.mll,v 1.35 1999-08-17 13:26:47 maranget Exp $" 

let verbose = ref 0 and silent = ref false
;;

let set_verbose s v =
  silent := s ; verbose := v
;;

exception Error of string
;;

let seen_par = ref false
;;

let my_int_of_string s =
  try int_of_string s
  with Failure "int_of_string" ->
    raise (Error ("Integer argument expected: ``"^s^"''"))


let brace_nesting = ref 0
and arg_buff = Out.create_buff ()
and echo_buff = Out.create_buff ()
and tag_buff = Out.create_buff ()
;;

let echo = ref false
;;

let get_echo () = echo := false ; Out.to_string echo_buff
and start_echo () = echo := true ; Out.reset echo_buff
;;


exception Eof
;;
exception NoOpt
;;

let put_echo s =
  if !echo then Out.put echo_buff s
and put_echo_char c =
  if !echo then Out.put_char echo_buff c
;;

let put_both s =
  put_echo s ; Out.put arg_buff s
;;

let put_both_char c =
  put_echo_char c ; Out.put_char arg_buff c
;;

}

rule opt = parse
   '['
        {put_echo_char '[' ;
        opt2 lexbuf}
| ' '+ | '\n' + {put_echo (lexeme lexbuf) ; opt lexbuf}
|  eof  {raise Eof}
|  ""   {raise NoOpt}


and opt2 =  parse
    '{'         {incr brace_nesting;
                put_both_char '{' ; opt2 lexbuf}
  | '}'        { decr brace_nesting;
                 if !brace_nesting >= 0 then begin
                    put_both_char '}' ; opt2 lexbuf
                 end else begin
                   raise (Error "Bad brace nesting in optional argument")
                 end}
  | ']'
      {if !brace_nesting > 0 then begin
        put_both_char ']' ; opt2 lexbuf
      end else begin
        put_echo_char ']' ;
        Out.to_string arg_buff
      end}
  | _
      {let s = lexeme_char lexbuf 0 in
      put_both_char s ; opt2 lexbuf }

and arg = parse
    ' '+ | '\n'+  {put_echo (lexeme lexbuf) ; arg lexbuf}
  | '{'
      {incr brace_nesting;
      put_echo_char '{' ;
      arg2 lexbuf}
  | '%' [^'\n']* '\n'
     {put_echo (lexeme lexbuf) ; arg lexbuf}
  | "\\box" '\\' (['A'-'Z' 'a'-'z']+ '*'? | [^ 'A'-'Z' 'a'-'z'])
     {let lxm = lexeme lexbuf in
     put_echo lxm ;
     lxm}
  | '\\' ( [^'A'-'Z' 'a'-'z'] | ('@' ? ['A'-'Z' 'a'-'z']+ '*'?))
     {put_both (lexeme lexbuf) ;
     skip_blanks lexbuf}
  | '#' ['1'-'9']
     {let lxm = lexeme lexbuf in
     put_echo lxm ; lxm}
  | [^ '}']
      {let c = lexeme_char lexbuf 0 in
      put_both_char c ;
      Out.to_string arg_buff}
  | eof    {raise Eof}
  | ""     {raise (Error "Argument expected")}

and arg_verbatim = parse
  | '{'
      {start_echo();
       in_arg_verbatim lexbuf}
  | ""
      {raise (Error "Ill starting verbatim Arg")}

and in_arg_verbatim = parse
  | '}'
      {get_echo()}
  | _
      {put_echo (lexeme lexbuf);
       in_arg_verbatim lexbuf}

and skip_blanks = parse
  ' '+
    {seen_par := false ;
    put_echo (lexeme lexbuf) ;
    skip_blanks lexbuf}
| '\n'
    {put_echo_char '\n' ; more_skip lexbuf}
| ""
    {Out.to_string arg_buff}

and more_skip = parse
  '\n'+
   {seen_par := true ;
   put_echo (lexeme lexbuf) ;
   more_skip lexbuf}
| ""
  {Out.to_string arg_buff}

and skip_equal = parse
    [' ']* '='? [' ']* {()}

and arg2 = parse
  '{'         
     {incr brace_nesting;
     put_both_char '{' ;
     arg2 lexbuf}
| '}'
     {decr brace_nesting;
     if !brace_nesting > 0 then begin
       put_both_char '}' ; arg2 lexbuf
     end else begin
       put_echo_char '}' ;
       Out.to_string arg_buff
     end}
| "\\{" | "\\}" | "\\\\"
      {let s = lexeme lexbuf in
      put_both s ; arg2 lexbuf }
| eof    {raise Eof}
| _
      {let c = lexeme_char lexbuf 0 in
      put_both_char c ; arg2 lexbuf }

and csname = parse
  [' ''\n']+ {put_echo (lexeme lexbuf) ; csname lexbuf}
| '{'? "\\csname" ' '+
      {let lxm = lexeme lexbuf in
      put_echo lxm ; Out.put_char arg_buff '\\' ;
      incsname lexbuf}
| ""  {arg lexbuf}

and incsname = parse
  "\\endcsname"  '}'?
    {let lxm = lexeme lexbuf in
    put_echo lxm ; Out.to_string arg_buff}
| _ 
    {put_both_char (lexeme_char lexbuf 0) ;
    incsname lexbuf}
| eof           {raise (Error "End of file in command name")}

and cite_arg = parse
  ' '* '{'   {cite_args_bis lexbuf}

and cite_args_bis = parse
  [^'}'' ''\n''%'',']* {let lxm = lexeme lexbuf in lxm::cite_args_bis lexbuf}
|  '%' [^'\n']* '\n' {cite_args_bis lexbuf}
| ','         {cite_args_bis lexbuf}
| [' ''\n']+ {cite_args_bis lexbuf}
| '}'         {[]}

and macro_names = parse
  eof {[]}
| '\\' (('@'? ['A'-'Z' 'a'-'z']+ '*'?) | [^ 'A'-'Z' 'a'-'z'])
  {let name = lexeme lexbuf in
  name :: macro_names lexbuf}
| _   {macro_names lexbuf}

and num_arg = parse
  ['0'-'9']+ 
    {let lxm = lexeme lexbuf in
    my_int_of_string lxm}
|  "'" ['0'-'7']+ 
    {let lxm = lexeme  lexbuf in
    my_int_of_string ("0o"^String.sub lxm 1 (String.length lxm-1))}
|  '"' ['0'-'9' 'a'-'f' 'A'-'F']+ 
    {let lxm = lexeme  lexbuf in
    my_int_of_string ("0x"^String.sub lxm 1 (String.length lxm-1))}
| '`' '\\' _
    {let c = lexeme_char lexbuf 2 in
    Char.code c}
| '`' _
    {let c = lexeme_char lexbuf 1 in
    Char.code c}
| "" {raise (Error "Bad syntax in latex numerical argument")}

and input_arg = parse
  [' ''\n']      {put_echo (lexeme lexbuf) ; input_arg lexbuf}
| [^'\n''{'' ']+ {let lxm = lexeme lexbuf in put_echo lxm ; lxm}
| ""             {arg lexbuf}  

and get_sup_sub = parse
  ' '* '^'
    {let sup = arg lexbuf in
    sup,get_sub lexbuf}
| ' '* '_'
    {let sub = arg lexbuf in
    get_sup lexbuf,sub}
| "" {("","")}

and get_sup = parse
  ' '* '^'  {arg lexbuf}
| ""   {""}

and get_sub = parse
  ' '* '_'  {arg lexbuf}
| ""   {""}

and defargs = parse 
  '#' ['1'-'9']
    {let lxm = lexeme lexbuf in
    put_echo lxm ;
    lxm::defargs lexbuf}
| [^'#' '{']+
    {Misc.warning
        ("not implemented: \\def with delimiting characters: ``"
         ^lexeme lexbuf^"''") ;
    defargs lexbuf}
| "" {[]}

and tagout = parse
  '<'  {intag lexbuf}
| "&nbsp;" {Out.put tag_buff " " ; tagout lexbuf}
| "&gt;" {Out.put tag_buff ">" ; tagout lexbuf}
| "&lt;" {Out.put tag_buff "<" ; tagout lexbuf}
| _    {Out.put tag_buff (lexeme lexbuf) ; tagout lexbuf}
| eof  {Out.to_string tag_buff}

and intag = parse
  '>'  {tagout lexbuf}
| '"'  {instring lexbuf}
| _    {intag lexbuf}
| eof  {Out.to_string tag_buff}

and instring = parse
  '"'  {intag lexbuf}
| '\\' '"' {instring lexbuf}
| _    {instring lexbuf}
| eof  {Out.to_string tag_buff}


and checklimits = parse
  "\\limits"   {true}
| "\\nolimits" {false}
| ""           {false}
