import dynlib, os, posix
var libPtr = LoadLib("<math.h>")
echo(cast[int](libPtr))
var funcPtr = checkedSymAddr(libPtr, "sqrt")
echo(cast[int](funcPtr))
