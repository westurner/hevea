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

let header = "$Id: cross.ml,v 1.9 2000-01-26 17:08:37 maranget Exp $" 
let verbose = ref 0
;;

let table = Hashtbl.create 37
;;

let add name file =  
  if !verbose > 0 then
      prerr_endline ("Register "^name^" in "^file) ;
  try
    let _ = Hashtbl.find table name in
    Location.print_pos () ;
    prerr_endline ("Warning, multiple definitions for anchor: "^name) ;
  with
  | Not_found ->
      Hashtbl.add table name file
;;


let fullname myfilename name =
  try
    let filename = Hashtbl.find table name in
    let newname =
      if myfilename = filename  then
      "#"^name
      else
        filename^"#"^name in
    if !verbose > 0 then
      prerr_endline ("From "^name^" to "^newname) ;
    newname
  with Not_found -> begin
    Location.print_pos () ;
    prerr_endline ("Warning, cannot find anchor: "^name) ;
    raise Not_found
  end
;;

    
