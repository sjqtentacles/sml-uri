(* Tests for sml-uri. Reference-resolution vectors are from RFC 3986 5.4. *)

structure UriTests =
struct
  open Harness

  fun run () =
    let
      val () = section "percent codec"
      val () = checkString "decode %2F" ("/", Percent.decode "%2F")
      val () = checkString "decode lowercase hex" ("/", Percent.decode "%2f")
      val () = checkString "encode space" ("%20", Percent.encode " ")
      val () = checkString "encode unreserved untouched" ("aZ9-._~", Percent.encode "aZ9-._~")
      val () = checkString "encode reserved" ("a%2Fb%3Fc", Percent.encode "a/b?c")
      val () = checkString "roundtrip" ("hello world/&=", Percent.decode (Percent.encode "hello world/&="))
      val () = checkString "lone percent left literal" ("%", Percent.decode "%")
      val () = checkString "short percent left literal" ("%2", Percent.decode "%2")
      val () = checkString "form encode space -> +" ("a+b", Percent.encodeForm "a b")
      val () = checkString "form decode + -> space" ("a b", Percent.decodeForm "a+b")

      val () = section "query"
      val () = checkBool "parse pairs"
                 (true, Query.parse "a=1&b=2" = [("a","1"),("b","2")])
      val () = checkBool "parse decodes"
                 (true, Query.parse "name=John+Doe&city=N%2FA" = [("name","John Doe"),("city","N/A")])
      val () = checkBool "bare key" (true, Query.parse "flag" = [("flag","")])
      val () = checkBool "empty -> []" (true, Query.parse "" = [])
      val () = checkString "build" ("a=1&b=hello+world", Query.build [("a","1"),("b","hello world")])
      val () = checkBool "get first" (true, Query.get (Query.parse "x=1&x=2") "x" = SOME "1")
      val () = checkBool "getAll" (true, Query.getAll (Query.parse "x=1&x=2&y=3") "x" = ["1","2"])

      val () = section "uri parse / toString round-trip"
      fun roundtrips s = Uri.toString (Uri.parse s) = s
      val () = checkBool "full uri" (true, roundtrips "http://h/a?b=c#d")
      val () = checkBool "with userinfo+port" (true, roundtrips "https://user@host:8443/p/q?x#y")
      val () = checkBool "mailto (no authority)" (true, roundtrips "mailto:a@b.com")
      val () = checkBool "relative path only" (true, roundtrips "../a/b")
      val () = checkBool "absolute path only" (true, roundtrips "/a/b/c")
      val () = checkBool "query only" (true, roundtrips "?just=query")
      val () = checkBool "fragment only" (true, roundtrips "#frag")
      val () = checkBool "scheme empty path" (true, roundtrips "foo:")

      val () = section "uri component extraction"
      val u = Uri.parse "http://example.com:80/path?a=1&b=2#sec"
      val () = checkBool "scheme" (true, #scheme u = SOME "http")
      val () = checkBool "authority" (true, #authority u = SOME "example.com:80")
      val () = checkString "path" ("/path", #path u)
      val () = checkBool "query" (true, #query u = SOME "a=1&b=2")
      val () = checkBool "fragment" (true, #fragment u = SOME "sec")
      val () = checkBool "queryParams" (true, Uri.queryParams u = [("a","1"),("b","2")])

      val () = section "reference resolution (RFC 3986 5.4 examples)"
      val base = "http://a/b/c/d;p?q"
      fun res r = Uri.resolveStr base r
      val () = checkString "g" ("http://a/b/c/g", res "g")
      val () = checkString "./g" ("http://a/b/c/g", res "./g")
      val () = checkString "g/" ("http://a/b/c/g/", res "g/")
      val () = checkString "/g" ("http://a/g", res "/g")
      val () = checkString "?y" ("http://a/b/c/d;p?y", res "?y")
      val () = checkString "g?y" ("http://a/b/c/g?y", res "g?y")
      val () = checkString "#s" ("http://a/b/c/d;p?q#s", res "#s")
      val () = checkString "../g" ("http://a/b/g", res "../g")
      val () = checkString "../../g" ("http://a/g", res "../../g")
      val () = checkString "../.." ("http://a/", res "../..")
      val () = checkString "." ("http://a/b/c/", res ".")
      val () = checkString "absolute ref" ("https://x/y", res "https://x/y")
      val () = checkString "empty -> base" ("http://a/b/c/d;p?q", res "")
    in
      ()
    end
end
