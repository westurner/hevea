open Parse_opts
open Html

type ok = Some of int * string * string * string | None

let table = ref (Array.make 2 None)
and some = ref false
;;

let current = ref 0
;;
let register i mark text anchor =
  some := true ;
  let b =  Array.length !table < !current in
  if Array.length !table <= !current then begin
    let t = Array.make (2* !current) None in
    Array.blit !table 0 t 0 (Array.length !table) ;
    table := t
  end ;
  begin match !table.(!current) with
    None -> ()
  | Some (_,_,_,_) -> begin
      Location.print_pos () ;
      prerr_endline "Warning: erasing previous footnote"
    end
  end ;
  !table.(!current) <- Some (i,mark,text,anchor) ;
  incr current
;;

let sec_value s = match String.uppercase s with
  "DOCUMENT"|"" -> 0
| "PART" -> 1
| "CHAPTER" -> 2
| "SECTION" -> 3
| _         -> 4
;;

let flush lexer sec_notes sec_here =
  if !some && sec_value sec_here <= sec_value sec_notes then begin
    some := false ;
    Html.put "<!--BEGIN NOTES " ;
    Html.put sec_notes ;
    Html.put "-->\n" ;
    lexer "\\footnoterule" ;
    Html.open_block "DL" "" ;
    let t = !table in
    for i = 0 to Array.length t - 1 do
      match t.(i) with
        None -> ()
      | Some (_,m,txt,anchor) ->
          t.(i) <- None ;
          Html.item (fun s ->
             lexer ("\\@openanchor{text}{note}{"^anchor^"}") ;
             Html.put s ;
             lexer ("\\@closeanchor")) m;
          Html.put txt ;
          Html.put_char '\n'
    done ;
    Html.force_block "DL" "" ;
    Html.put "<!--END NOTES-->" ;
    current := 0;
  end
;;