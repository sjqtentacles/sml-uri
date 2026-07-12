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

      val () = section "percent normalization (RFC 3986 6.2.2)"
      val () = checkString "decode unreserved %7e -> ~" ("~", Percent.normalize "%7e")
      val () = checkString "uppercase reserved %2f -> %2F" ("%2F", Percent.normalize "%2f")
      val () = checkString "mixed" ("a~b%2F", Percent.normalize "a%7eb%2f")
      val () = checkString "lone percent left literal" ("%", Percent.normalize "%")

      val () = section "remove_dot_segments"
      (* RFC 3986 5.2.4's own worked example. *)
      val () = checkString "canonical" ("/a/g", Uri.removeDotSegments "/a/b/c/./../../g")
      val () = checkString "one-up" ("/a/b/g", Uri.removeDotSegments "/a/b/c/./../g")
      val () = checkString "trailing dot" ("/a/b/", Uri.removeDotSegments "/a/b/c/..")

      val () = section "syntax-based normalization (RFC 3986 section 6)"
      fun norm s = Uri.toString (Uri.normalize (Uri.parse s))
      val () = checkString "scheme+host+port+path"
                 ("http://example.com/a/c", norm "HTTP://Example.COM:80/a/./b/../c")
      val () = checkString "keeps non-default port"
                 ("http://example.com:8080/", norm "HTTP://Example.COM:8080/")
      val () = checkString "https default port dropped"
                 ("https://example.com/", norm "HTTPS://Example.COM:443/")
      val () = checkString "percent in path decoded"
                 ("http://h/~x", norm "http://h/%7ex")

      val () = section "component setters"
      val u2 = Uri.parse "http://h/p?q=1#frag"
      val () = checkString "withoutFragment drops #frag" ("http://h/p?q=1", Uri.toString (Uri.withoutFragment u2))
      val () = checkString "withoutQuery drops ?q" ("http://h/p#frag", Uri.toString (Uri.withoutQuery u2))
      val () = checkString "withPath" ("http://h/new?q=1#frag", Uri.toString (Uri.withPath u2 "/new"))
      val () = checkString "withQuery" ("http://h/p?z=9#frag", Uri.toString (Uri.withQuery u2 "z=9"))
      val () = checkString "withFragment" ("http://h/p?q=1#top", Uri.toString (Uri.withFragment u2 "top"))

      val () = section "relativize (inverse of resolve)"
      val rb = Uri.parse "http://a/b/"
      val rt = Uri.parse "http://a/b/c/d"
      val () = checkString "relative path" ("c/d", Uri.toString (Uri.relativize rb rt))
      val () = checkBool "round-trips through resolve"
                 (true, Uri.toString (Uri.resolve rb (Uri.relativize rb rt)) = Uri.toString rt)
      val () = checkBool "different authority -> target unchanged"
                 (true, Uri.relativize rb (Uri.parse "http://z/x") = Uri.parse "http://z/x")

      val () = section "sml-check properties"

      (* Arbitrary-byte generator: percent-encoding operates on raw bytes,
         not text, so we exercise the full 0..255 range. *)
      val genByte = Check.charRange (Char.chr 0, Char.chr 255)
      val genBytesStr = Check.stringOf genByte

      (* prop: Percent.decode (Percent.encode s) = s for arbitrary bytes. *)
      val () =
        Harness.check "prop: Percent.decode (Percent.encode s) = s"
          (case Check.quickCheck
                  (Check.forAll genBytesStr (fn s => s)
                     (fn s => Percent.decode (Percent.encode s) = s)) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      (* prop: Percent.decodeForm (Percent.encodeForm s) = s for arbitrary
         bytes (space <-> '+' handling doesn't disturb the round trip). *)
      val () =
        Harness.check "prop: Percent.decodeForm (Percent.encodeForm s) = s"
          (case Check.quickCheck
                  (Check.forAll genBytesStr (fn s => s)
                     (fn s => Percent.decodeForm (Percent.encodeForm s) = s)) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      (* prop: Query.parse (Query.build pairs) = pairs for generated
         key/value pairs drawn from the full non-NUL byte range (form
         encoding must escape anything that would otherwise be ambiguous,
         e.g. '&', '=', '+', '%'). *)
      val genQueryByte = Check.charRange (Char.chr 1, Char.chr 255)
      val genQueryStr = Check.stringOf genQueryByte
      val genQueryPairs = Check.listOf (Check.tuple2 (genQueryStr, genQueryStr))
      fun showPairs ps =
        "[" ^ String.concatWith "," (List.map (fn (k, v) => k ^ "=" ^ v) ps) ^ "]"
      val () =
        Harness.check "prop: Query.parse (Query.build pairs) = pairs"
          (case Check.quickCheck
                  (Check.forAll genQueryPairs showPairs
                     (fn ps => Query.parse (Query.build ps) = ps)) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      (* prop: for a generated well-formed URI string (safe alnum
         scheme/authority/path/query/fragment, needing no percent-encoding),
         toString o parse is the identity -- generalizing the fixed
         "roundtrips" vectors above to random shapes. *)
      val genAlnumChar = Check.oneof [Check.charRange (#"a", #"z"), Check.charRange (#"0", #"9")]
      val genAlnum = Check.nonEmptyListOf genAlnumChar
      fun implodeGen g = Check.map String.implode g
      val genScheme = implodeGen (Check.nonEmptyListOf (Check.charRange (#"a", #"z")))
      val genAuthority = implodeGen genAlnum
      val genSeg = implodeGen genAlnum
      val genPath = Check.map (fn segs => "/" ^ String.concatWith "/" segs) (Check.listOf genSeg)
      val genQueryOpt =
        Check.option
          (Check.map
             (fn kvs => String.concatWith "&" (List.map (fn (k, v) => k ^ "=" ^ v) kvs))
             (Check.listOf (Check.tuple2 (genSeg, genSeg))))
      val genFragOpt = Check.option genSeg
      val genUriStr =
        Check.bind genScheme (fn sch =>
        Check.bind genAuthority (fn auth =>
        Check.bind genPath (fn path =>
        Check.bind genQueryOpt (fn q =>
        Check.map
          (fn f =>
             sch ^ "://" ^ auth ^ path
             ^ (case q of NONE => "" | SOME qs => "?" ^ qs)
             ^ (case f of NONE => "" | SOME fs => "#" ^ fs))
          genFragOpt))))
      val () =
        Harness.check "prop: Uri.toString (Uri.parse s) = s for safe URI strings"
          (case Check.quickCheck
                  (Check.forAll genUriStr (fn s => s)
                     (fn s => Uri.toString (Uri.parse s) = s)) of
               Check.Passed _ => true
             | Check.Failed _ => false)
    in
      ()
    end
end
