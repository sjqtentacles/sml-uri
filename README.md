# sml-uri

[![CI](https://github.com/sjqtentacles/sml-uri/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-uri/actions/workflows/ci.yml)

RFC 3986 URIs and `application/x-www-form-urlencoded` queries for Standard ML:
percent codec, generic URI parse/serialize, reference resolution, and query
key/value handling.

Pure Standard ML over the Basis library -- no dependencies. The URI parser is
a direct, total implementation of the RFC 3986 Appendix B decomposition and
the section 5.2 reference-resolution algorithm (no parser-combinator
dependency), so the whole library is self-contained and deterministic.
Verified on **MLton** and **Poly/ML** against the RFC 3986 section 5.4
resolution examples.

## Modules

| Structure | Spec | Purpose |
| --- | --- | --- |
| `Percent` | RFC 3986 section 2 | `encode`/`decode`, form `+`-encoding |
| `Query`   | WHATWG urlencoded | parse/build/get/getAll over ordered pairs |
| `Uri`     | RFC 3986 | parse, toString, resolve, queryParams |

## API

```sml
structure Percent : sig
  val encode : string -> string        val decode : string -> string
  val encodeForm : string -> string    val decodeForm : string -> string
end

structure Query : sig
  type query = (string * string) list
  val parse : string -> query          val build : query -> string
  val get : query -> string -> string option
  val getAll : query -> string -> string list
end

structure Uri : sig
  type uri =
    { scheme : string option, authority : string option, path : string
    , query : string option, fragment : string option }
  val parse : string -> uri            val toString : uri -> string
  val resolve : uri -> uri -> uri      val resolveStr : string -> string -> string
  val removeDotSegments : string -> string
  val normalize : uri -> uri           val relativize : uri -> uri -> uri
  val withPath : uri -> string -> uri  val withQuery : uri -> string -> uri
  val withFragment : uri -> string -> uri
  val withoutQuery : uri -> uri        val withoutFragment : uri -> uri
  val queryParams : uri -> (string * string) list
end
```

URI components are stored *raw* (still percent-encoded), so `toString o parse`
is the exact identity; decode individual pieces with `Percent.decode`.

### Example

```sml
val u = Uri.parse "http://example.com/path?a=1&b=2#frag"
val () = print (#path u ^ "\n")                       (* /path *)
val q = Uri.queryParams u                              (* [("a","1"),("b","2")] *)
val abs = Uri.resolveStr "http://a/b/c/d;p?q" "../g"   (* http://a/b/g *)
```

### Normalization, relativization & setters

`Uri.normalize` applies RFC 3986 section 6 *syntax-based normalization*:
lowercases the scheme and host, drops the default port for the scheme (http
80, https 443, ftp 21, ws 80, wss 443), normalizes percent-encoding (uppercase
hex digits, decode unreserved bytes), and runs `removeDotSegments` on the path.
`Percent.normalize` exposes the percent-encoding part on its own.

`relativize base target` is the inverse of `resolve`: when both share a scheme
and authority and base's path is a prefix of target's, it yields a relative
reference such that `resolve base (relativize base target) = target` (otherwise
the target is returned unchanged). The `with*` helpers return a copy with one
component replaced or dropped.

```sml
Uri.toString (Uri.normalize (Uri.parse "HTTP://Example.COM:80/a/./b/../c"))
  (* "http://example.com/a/c" *)
Uri.removeDotSegments "/a/b/c/./../../g"            (* "/a/g" *)
Percent.normalize "%7e"                              (* "~" *)
Uri.toString (Uri.withoutFragment (Uri.parse "http://h/p#frag"))  (* "http://h/p" *)
val rel = Uri.relativize (Uri.parse "http://a/b/") (Uri.parse "http://a/b/c/d")
  (* Uri.toString rel = "c/d" *)
```

## CLI

```sh
make cli
./bin/uri parse   "http://h/a?b=c#d"
./bin/uri resolve "http://a/b/c/d;p?q" "../g"
./bin/uri encode  "hello world/&"
./bin/uri decode  "%2F"
```

## Build & test

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make cli         # build ./bin/uri
make example     # build + run the demo
make clean
```

## Demo

[`examples/demo.sml`](examples/demo.sml) parses a fixed URI into its components,
round-trips and normalizes it, resolves a relative reference, and runs the
percent codec. It is pure string processing, so the output is identical on every
run and on both compilers. Run it with:

```
$ make example
parse https://User@Example.COM:443/a/./b/../c?x=1&y=2#frag
  scheme    = "https"
  authority = "User@Example.COM:443"
  path      = "/a/./b/../c"
  query     = "x=1&y=2"
  fragment  = "frag"
  toString roundtrip = https://User@Example.COM:443/a/./b/../c?x=1&y=2#frag
  normalized         = https://User@example.com/a/c?x=1&y=2#frag

queryParams: x=1, y=2

resolve "http://a/b/c/d;p?q" "../../g" = http://a/g
removeDotSegments "/a/b/c/./../../g" = /a/g

Percent.encode "a b/c?" = a%20b%2Fc%3F
Percent.decode "a%20b%2Fc" = a b/c
```

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-uri
smlpkg sync
```

Reference `lib/github.com/sjqtentacles/sml-uri/sml-uri.mlb` from your own
`.mlb`, or feed `sources.mlb` to `tools/polybuild` (Poly/ML).

## Tests

44 deterministic checks: percent codec edge cases, form `+`-encoding, query
parse/build/get, URI round-trips (full, mailto, relative, query-only,
fragment-only, empty-path scheme), component extraction, and the full set of
RFC 3986 section 5.4 reference-resolution examples. Run `make all-tests`.

## License

MIT. See [LICENSE](LICENSE).
