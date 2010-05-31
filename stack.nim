# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# stack
import parser

type
  TDict* = seq[tuple[name: string, value: PType]]

  TTypes* = enum
    ntInt,
    ntFloat,
    ntString,
    ntList,
    ntQuot,
    ntDict
    
  PType* = ref TType
  TType* = object
    case kind*: TTypes
    of ntInt:
      iValue*: int64
    of ntFloat:
      fValue*: float64
    of ntString:
      value*: string
    of ntList:
      lValue*: seq[PType]
    of ntQuot:
      qValue*: PNaelNode
    of ntDict:
      dValue*: TDict
      
  TStack* = tuple[stack: seq[PType], limit: int]

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
    


