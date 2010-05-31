# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# Interpreter - Executes the AST
import parser, strutils, os

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
  
  ERuntimeError* = object of EBase
  EVar* = object of EBase

# Stack
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

proc newVariables*(): PType =
  new(result)
  result.kind = ntDict
  result.dValue = @[]
  
proc addStandard*(vars: var PType) =
  var appDir = newString(os.getApplicationDir())
  var pathVar = newList(@[appDir])
  vars.dValue.add(("__path__", pathVar))
  
  var modulesVar: PType # [["name", {locals}, {globals}], ...]
  modulesVar = newList(@[])
  vars.dValue.add(("__modules__", modulesVar))
  
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

proc toPType(item: PNaelNode): PType =
  ## Converts a PNaelNode of any kind. Into a corresponding PType
  new(result)
  
  case item.kind
  of nnkIntLit:
    result = newInt(item.iValue)
  of nnkStringLit:
    result = newString(item.value)
  of nnkFloatLit:
    result = newFloat(item.fValue)
  of nnkListLit:
    result.kind = ntList
    result.lValue = @[]
  of nnkQuotLit:
    result.kind = ntQuot
    result.lValue = @[]
  else:
    raise newException(ESystem, "Error: Unexpected nael node kind, " & $item.kind)
  
  # Add all the children of quotations and lists.
  if item.kind == nnkListLit or item.kind == nnkQuotLit:
    for node in items(item.children):
      case node.kind
      of nnkCommand, nnkVarDeclar, nnkVarSet, nnkFunc:
        # Commands are not allowed in Lists.
        if item.kind == nnkListLit:
          raise newException(ERuntimeError, "Error: $1 not allowed in a list literal" % [$item.kind])
        elif item.kind == nnkQuotLit:
          result.lValue.add(newCmnd(node.value))
          
      of nnkIntLit, nnkStringLit, nnkFloatLit, nnkListLit, nnkQuotLit:
        result.lValue.add(toPType(node))

proc command*(cmnd: string, dataStack: var TStack, vars, gvars: var PType) # from core.nim

proc interpret*(ast: seq[PNaelNode], dataStack: var TStack, vars, gvars: var PType) =
  for node in items(ast):
    case node.kind
    of nnkCommand:
      command(node.value, dataStack, vars, gvars)
    of nnkIntLit, nnkStringLit, nnkFloatLit, nnkListLit, nnkQuotLit:
      dataStack.push(toPType(node))
    of nnkVarDeclar:
      vars.declVar(node.value)
    of nnkVarSet:
      vars.setVar(node.name, toPType(node.setValue)) 
    
    else:
      #

include core # I know this is kind of bad... but i want to have all those
             # commands in a seperate module.

var dataStack = newStack(200)
var vars = newVariables() # 'main' variables(They act as both local and global)
vars.addStandard()

when isMainModule:
  var ast = parse("\"hello\" import")
  interpret(ast, dataStack, vars, vars)
  
  if dataStack.stack.len() > 0:
    var result = "stack["
    for i in items(dataStack.stack):
      result.add($i & ", ")
    result.add("]")
    echo(result)