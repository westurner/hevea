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

val symbols : bool ref
val iso : bool ref
type language = Francais | English
val language : language  ref
type destination = Html | Text | Info
val destination : destination ref
val mathml : bool ref
val entities : bool ref
val pedantic : bool ref
val width : int ref
val read_idx : bool ref
val except : string list ref
val path : string list ref
val warning : string -> unit

val styles : string list
val base_in : string
val name_in : string
val base_out : string
val name_out : string
