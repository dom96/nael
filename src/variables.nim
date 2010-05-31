# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# variables

proc newVariables*(): PType =
  new(result)
  result.kind = ntDict

# I know that there is a lot of repetition, i don't know how i could do this better though.
proc addVar*(vars: var PType, name: string, theVar: PType) =
  # TODO: Check if the name contains illegal characters.
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  vars.dValue.add((name, theVar))
  
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
      
  