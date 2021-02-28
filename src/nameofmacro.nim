import std/macros


macro nameof*(x: typed): string =
  case x.kind
  of nnkSym, nnkIdent, nnkClosedSymChoice:
    return x.toStrLit
  of nnkDotExpr:
    return x.last.toStrLit
  of nnkBracketExpr:
    return x[0].toStrLit
  else:
    error("It is not a symbol or an identifier.", x)

