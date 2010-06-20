import naelAPI, dynlib

proc sqrt*(x: PType): PType {.exportc: "nael_sqrt".} =
  new(result)

  result.kind = ntFloat
  if x.kind == ntFloat:
    var lib = LoadLib("<math.h>")
    var funcPtr = checkedSymAddr(lib, "sqrt")
    var func = cast[proc(x: float): float](funcPtr)
    
    result.fValue = func(x.fValue)
    
  else:
    raise invalidTypeErr($x.kind, "float", "sqrt")