(* demo.sml - parse, normalize, and resolve fixed URIs (RFC 3986). Everything
   here is pure string processing, so the output is identical on every run and
   on both compilers. No reals are involved. *)

fun opt NONE = "(none)"
  | opt (SOME s) = "\"" ^ s ^ "\""

val raw = "https://User@Example.COM:443/a/./b/../c?x=1&y=2#frag"
val u = Uri.parse raw

val () = print ("parse " ^ raw ^ "\n")
val () = print ("  scheme    = " ^ opt (#scheme u) ^ "\n")
val () = print ("  authority = " ^ opt (#authority u) ^ "\n")
val () = print ("  path      = \"" ^ #path u ^ "\"\n")
val () = print ("  query     = " ^ opt (#query u) ^ "\n")
val () = print ("  fragment  = " ^ opt (#fragment u) ^ "\n")
val () = print ("  toString roundtrip = " ^ Uri.toString u ^ "\n")
val () = print ("  normalized         = " ^ Uri.toString (Uri.normalize u) ^ "\n")

val () = print ("\nqueryParams: "
                ^ String.concatWith ", "
                    (List.map (fn (k, v) => k ^ "=" ^ v) (Uri.queryParams u)) ^ "\n")

val () = print ("\nresolve \"http://a/b/c/d;p?q\" \"../../g\" = "
                ^ Uri.resolveStr "http://a/b/c/d;p?q" "../../g" ^ "\n")
val () = print ("removeDotSegments \"/a/b/c/./../../g\" = "
                ^ Uri.removeDotSegments "/a/b/c/./../../g" ^ "\n")

val () = print ("\nPercent.encode \"a b/c?\" = " ^ Percent.encode "a b/c?" ^ "\n")
val () = print ("Percent.decode \"a%20b%2Fc\" = " ^ Percent.decode "a%20b%2Fc" ^ "\n")
