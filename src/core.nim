# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 31 May 2010

# core - Implements commands like 'print'
import unity

proc interpretQuotation*(quot: PType, dataStack: var TStack, vars: var PType)

proc command*(cmnd: string, dataStack: var TStack, vars: var PType) =
  case cmnd
  of "print":
    var first = dataStack.pop()
    echo($first)
  of "call":
    var first = dataStack.pop()
    interpretQuotation(first, dataStack, vars)
  else:
    var tVar = vars.getVar(cmnd)
    if tVar == nil:
      raise newException(EVar, "Error: $1 is not declared.")
    dataStack.push(tVar)
    
    # TODO: Functions

proc interpretQuotation*(quot: PType, dataStack: var TStack, vars: var PType) =
  if quot.kind != ntQuot:
    raise newException(EInvalidValue, "Error: Argument given is not a quotation")
  
  for item in items(quot.lvalue):
    case item.kind
    of ntInt, ntFloat, ntString, ntList, ntQuot, ntDict, ntNil:
      dataStack.push(item)
    of ntCmnd:
      command(item.value, dataStack, vars)
