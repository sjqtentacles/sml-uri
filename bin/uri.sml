(* bin/uri.sml -- MLton CLI for sml-uri.

   Usage:
     uri parse   <uri>            print components, one per line
     uri resolve <base> <ref>     print the resolved absolute reference
     uri encode  <string>         percent-encode
     uri decode  <string>         percent-decode *)

fun pr s = print (s ^ "\n")

fun showOpt label NONE = pr (label ^ ": -")
  | showOpt label (SOME v) = pr (label ^ ": " ^ v)

fun doParse s =
  let val u = Uri.parse s in
    showOpt "scheme" (#scheme u);
    showOpt "authority" (#authority u);
    pr ("path: " ^ #path u);
    showOpt "query" (#query u);
    showOpt "fragment" (#fragment u)
  end

fun usage () =
  (TextIO.output (TextIO.stdErr,
     "usage: uri (parse <uri> | resolve <base> <ref> | encode <s> | decode <s>)\n");
   OS.Process.exit OS.Process.failure)

fun main () =
  case CommandLine.arguments () of
      ["parse", s]        => doParse s
    | ["resolve", b, r]   => pr (Uri.resolveStr b r)
    | ["encode", s]       => pr (Percent.encode s)
    | ["decode", s]       => pr (Percent.decode s)
    | _                   => usage ()

val () = main ()
