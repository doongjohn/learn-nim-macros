import std/macros


macro nameofAux(x: typed): string =
  case x.kind
  of nnkSym, nnkIdent, nnkClosedSymChoice:
    return x.toStrLit
  of nnkDotExpr:
    return x.last.toStrLit
  of nnkBracketExpr:
    return x[0].toStrLit
  else:
    quote do: {.error: "It is not a symbol or an identifier.".}


template nameof*(x: typed): string =
  nameofAux(x)
