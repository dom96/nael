# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# variables
import stack, parser

proc newVariables*(): PType =
  new(result)
  result.kind = ntDict

# I know that there is a lot of repetition, i don't know how i could do this better though.
proc addVar*(vars: var PType, name: string, theVar: int64) =
  # TODO: Check if the name contains illegal characters.
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  var v: PType
  v.kind = ntInt
  v.iValue = theVar
  vars.dValue.add((name, v))
  
proc addVar*(vars: var PType, name: string, theVar: float64) =
  # TODO: Check if the name contains illegal characters.
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  var v: PType
  v.kind = ntFloat
  v.fValue = theVar
  vars.dValue.add((name, v))
  
proc addVar*(vars: var PType, name: string, theVar: string) =
  # TODO: Check if the name contains illegal characters.
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  var v: PType
  v.kind = ntString
  v.Value = theVar
  vars.dValue.add((name, v))
  
proc addVar*(vars: var PType, name: string, theVar: seq[PType]) =
  # TODO: Check if the name contains illegal characters.
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  var v: PType
  v.kind = ntList
  v.lValue = theVar
  vars.dValue.add((name, v))

proc addVar*(vars: var PType, name: string, theVar: PNaelNode) =
  # TODO: Check if the name contains illegal characters.
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  var v: PType
  v.kind = ntQuot
  v.qValue = theVar
  vars.dValue.add((name, v))
  
proc getVar*(vars: var PType, name: string): PType =
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  for vname, value in items(vars.dValue):
    if vname == name:
      return value
      
  return nil
  
proc remVar*(vars: var PType, name: string) =
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  for i in 0 .. len(vars.dValue)-1:
    if vars.dValue[i][0] == name:
      vars.dValue.del(i)
      
  