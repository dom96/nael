# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# variables
# This doesn't compile on it's own, compile unity.nim instead

type
  EVar* = object of EBase

proc newVariables*(): PType =
  new(result)
  result.kind = ntDict
  result.dValue = @[]
  
proc getVar*(vars: var PType, name: string): PType =
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  for vname, value in items(vars.dValue):
    if vname == name:
      return value
      
  return nil

proc getVarIndex*(vars: var PType, name: string): int =
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  for i in 0 .. len(vars.dValue)-1:
    if vars.dValue[i][0] == name:
      return i
      
  return -1
  
proc declVar*(vars: var PType, name: string) =
  # Declares a variable

  # TODO: Check if the name contains illegal characters.
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  if getVarIndex(vars, name) != -1:
    raise newException(EVar, "Error: $1 is already declared." % [name])

  var theVar: PType
  new(theVar)
  theVar.kind = ntNil

  vars.dValue.add((name, theVar))
  
proc setVar*(vars: var PType, name: string, theVar: PType) =
  # Sets a variables value.
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")
  
  var varIndex = vars.getVarIndex(name)
  if varIndex == -1:
    raise newException(EVar, "Error: $1 is not declared." % [name])
    
  vars.dValue[varIndex][1] = theVar
  
proc remVar*(vars: var PType, name: string) =
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  for i in 0 .. len(vars.dValue)-1:
    if vars.dValue[i][0] == name:
      vars.dValue.del(i)
      
  