# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# stack
type
  TDict* = seq[tuple[name: string, value: PType]]

  TTypes* = enum
    ntInt,
    ntFloat,
    ntString,
    ntList,
    ntQuot,
    ntDict,
    ntNil,
    ntCmnd # Exclusive to quotations.
    
  PType* = ref TType
  TType* = object
    case kind*: TTypes
    of ntInt:
      iValue*: int64
    of ntFloat:
      fValue*: float64
    of ntString, ntCmnd:
      value*: string
    of ntList, ntQuot:
      lValue*: seq[PType]
    of ntDict:
      dValue*: TDict
    of ntNil: nil
      
  TStack* = tuple[stack: seq[PType], limit: int]
  
  
proc `$`*(item: PType): string =
  result = ""

  case item.kind
  of ntInt:
    return $item.iValue
  of ntFloat:
    return $item.fValue
  of ntString, ntCmnd:
    return item.value
  of ntList:
    result.add("[")
    for i in 0 .. len(item.lValue)-1:
      result.add($item.lValue[i])
      if i < len(item.lValue)-1:
        result.add(", ")
    result.add("]")
      
  of ntQuot:
    result.add("(")
    for i in 0 .. len(item.lValue)-1:
      result.add($item.lValue[i])
      if i < len(item.lValue)-1:
        result.add(", ")
    result.add(")")
  of ntDict:
    result.add("__dict__")
  of ntNil:
    result.add("nil")

proc newStack*(limit: int): TStack =
  result.stack = @[]
  result.limit = limit

proc push*(stack: var TStack, item: PType) =
  if stack.stack.len() >= stack.limit:
    raise newException(EOverflow, "Error: Stack overflow")
    
  stack.stack.add(item)

proc pop*(stack: var TStack): PType =
  if stack.stack.len() < 1:
    raise newException(EOverflow, "Error: Stack underflow")
    
  return stack.stack.pop()

proc newInt*(value: int64): PType =
  new(result)
  result.kind = ntInt
  result.iValue = value
  
proc newFloat*(value: float64): PType =
  new(result)
  result.kind = ntFloat
  result.fValue = value

proc newString*(value: string): PType =
  new(result)
  result.kind = ntString
  result.value = value

proc newList*(value: seq[PType]): PType =
  new(result)
  result.kind = ntList
  result.lValue = value

proc newCmnd*(value: string): PType =
  new(result)
  result.kind = ntCmnd
  result.value = value
