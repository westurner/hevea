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

let header = "$Id: version.ml,v 1.25 2000-01-26 17:09:00 maranget Exp $" 
let real_version = "1.05-7"
let release_date = "2000-01-26"

let version =
  try
   let _ = String.index real_version '-' in
   real_version^" of "^release_date
  with
  | Not_found -> real_version
