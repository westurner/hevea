open Parse_opts

let finalize () =
  Image.finalize () ;
  Html.finalize ()
;;

let read_style name =
  try
    let name,chan =  Myfiles.open_tex name in
    let buf = Lexing.from_channel chan in
    Location.set name buf ;
    Latexscan.main buf ;
    Location.restore ()
  with Not_found -> ()
;;
 
let main () =
  try begin

    read_style "htmlgen.sty" ;

    begin match !files with
     [] -> files := ["article.sty"]
    | _ -> () end;

    let texfile = match !files with
      [] -> ""
    | x::rest ->
       if Filename.check_suffix x ".tex" then begin
         files := rest ;
         x
       end else "" in

    Image.base := begin match texfile with
      "" -> !Image.base
    | _   -> Filename.chop_suffix texfile ".tex" end ;

    let rec do_rec = function
      [] -> ()
    | x::rest ->
       do_rec rest ;
       read_style x in

    do_rec !files ;

    let basename = match texfile with "" -> ""
      | _ -> Filename.chop_suffix texfile ".tex" in

    Location.set_base basename ;

    Latexscan.out_file := begin match Filename.basename basename with
      "" ->  Out.create_chan stdout
    | s  -> Out.create_chan (open_out (s^".html")) end ;

        
    begin match texfile with
      "" -> Latexscan.no_prelude ()
    | _  ->
       let auxname = Filename.basename basename^".aux" in
       try
         let _,auxchan = Myfiles.open_tex auxname in
         let buf = Lexing.from_channel auxchan in
         Aux.main buf
       with Failure _ -> begin
         if !verbose > 0 then
           prerr_endline ("Cannot open aux file: "^auxname)
       end
    end ;
    let chan = match texfile with "" -> stdin | _ -> open_in texfile in
    let buf = Lexing.from_channel chan in
    Location.set texfile buf ;
    Image.start () ;
    Latexscan.main buf ;
    Location.restore () ;
    finalize ()
  end with x -> begin
    Location.print_pos () ;
    prerr_endline "Good bye" ;
    finalize () ; raise x
  end
;;   


begin try
  main ()
with x -> begin
  Location.print_pos () ;
  raise x
  end
end ;
exit 0;;
