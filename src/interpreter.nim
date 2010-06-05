# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# Interpreter - Executes the AST
import parser, strutils, os, times, math

type
  TDict* = seq[tuple[name: string, value: PType]]

  TTypes* = enum
    ntInt,
    ntFloat,
    ntString,
    ntBool,
    ntList,
    ntQuot,
    ntDict,
    ntNil,
    ntCmnd, # Exclusive to quotations.
    ntVar, # A pointer to a variable
    ntFunc, # Exclusively used only in variables
    ntASTNode # A PNaelNode - VarDeclar etc, Are declared with this in quotations
    
  PType* = ref TType
  TType* = object
    case kind*: TTypes
    of ntInt:
      iValue*: int64
    of ntFloat:
      fValue*: float64
    of ntString, ntCmnd:
      value*: string # for ntCmnd, name of cmnd.
    of ntBool:
      bValue*: bool
    of ntList, ntQuot:
      lValue*: seq[PType]
    of ntDict:
      dValue*: TDict
    of ntNil: nil
    of ntFunc:
      args*: seq[PType]
      quot*: PType
    of ntASTNode:
      node*: PNaelNode
    of ntVar:
      vvalue*: string
      loc*: int # 0 for local, 1 for global
      
  TStack* = tuple[stack: seq[PType], limit: int]
  
  ERuntimeError* = object of EBase

# Stack
proc toString*(item: PType, stack = False): string =
  result = ""

  case item.kind
  of ntInt:
    return $item.iValue
  of ntFloat:
    return $item.fValue
  of ntString, ntCmnd:
    if stack:
      return "\"" & item.value & "\""
    else:
      return item.value
      
  of ntBool:
    return $item.bValue
    
  of ntList:
    result.add("[")
    for i in 0 .. len(item.lValue)-1:
      result.add(toString(item.lValue[i]))
      if i < len(item.lValue)-1:
        result.add(", ")
    result.add("]")
      
  of ntQuot:
    result.add("(")
    for i in 0 .. len(item.lValue)-1:
      result.add(toString(item.lValue[i]))
      if i < len(item.lValue)-1:
        result.add(", ")
    result.add(")")
  of ntDict:
    result.add("__dict__")
  of ntNil:
    result.add("nil")
  of ntVar:
    result.add("<var '" & item.vvalue & "' loc=" & $item.loc & ">")
  of ntFunc:
    result.add("__func__")
  of ntAstNode:
    case item.node.kind:
    of nnkVarDeclar:
      result.add(item.node.value & " let")
    of nnkFunc:
      result.add("Func(" & item.node.fName & ")")
    else:
      raise newException(ERuntimeError, "Error: Unexpected AstNode in `$`, " & $item.node.kind)

proc isEqual*(first, second: PType): bool =
  if first.kind == second.kind:
    case first.kind
    of ntInt:
      return first.iValue == second.iValue
    of ntFloat:
      return first.fValue == second.fValue
    of ntString, ntCmnd, ntVar:
      return first.value == second.value
    of ntBool:
      return first.bValue == second.bValue
    of ntList, ntQuot:
      if len(first.lValue) == len(second.lValue):
        for i in 0 .. len(first.lValue)-1:
          if not isEqual(first.lValue[i], second.lValue[i]):
            return False
        return True
      else: return False
    of ntDict, ntFunc, ntAstNode:
      return first == second # FIXME: This probably doesn't work.
    of ntNil: return True
  else: return false

proc printStack*(stack: TStack) =
  if stack.stack.len() > 0:
    var result = "stack → ["
    for i in 0 .. len(stack.stack)-1:
      result.add(toString(stack.stack[i], True))
      if i < len(stack.stack)-1:
        result.add(", ")
      
    result.add("]")
    echo(result)  

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

proc newBool*(value: bool): PType =
  new(result)
  result.kind = ntBool
  result.bValue = value

proc newList*(value: seq[PType]): PType =
  new(result)
  result.kind = ntList
  result.lValue = value

proc newCmnd*(value: string): PType =
  new(result)
  result.kind = ntCmnd
  result.value = value

proc toPType(item: PNaelNode): PType
proc newFunc*(node: PNaelNode): PType =
  new(result)
  result.kind = ntFunc
  var args: seq[PType] = @[]
  for n in items(node.args.children):
    if n.kind == nnkCommand:
      args.add(newCmnd(n.value))
    else:
      raise newException(ERuntimeError, "Error: Function declaration incorrect, got " & $n.kind & " for args")

  result.args = args
  result.quot = toPType(node.quot)

proc newVar*(name: string, loc: int): PType =
  new(result)
  result.kind = ntVar
  result.vvalue = name
  result.loc = loc

proc newASTNode*(node: PNaelNode): PType = 
  new(result)
  result.kind = ntASTNode
  result.node = node

proc newVariables*(): PType =
  new(result)
  result.kind = ntDict
  result.dValue = @[]
  
proc addStandard*(vars: var PType) =
  ## Adds standard variables(__path__, __modules__) to vars. 
  var appDir = newString(os.getApplicationDir())
  var pathVar = newList(@[appDir])
  vars.dValue.add(("__path__", pathVar))
  
  var modulesVar: PType # [["name", {locals}, {globals}], ...]
  modulesVar = newList(@[])
  vars.dValue.add(("__modules__", modulesVar))
  
  vars.dValue.add(("false", newBool(False)))
  vars.dValue.add(("true", newBool(True)))
  
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
    raise newException(ERuntimeError, "Error: $1 is already declared." % [name])

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
    raise newException(ERuntimeError, "Error: Variable $1 is not declared." % [name])
    
  vars.dValue[varIndex][1] = theVar
  
proc remVar*(vars: var PType, name: string) =
  if vars.kind != ntDict:
    raise newException(EInvalidValue, "Error: The variable list needs to be a dict.")

  for i in 0 .. len(vars.dValue)-1:
    if vars.dValue[i][0] == name:
      vars.dValue.del(i)
      return
      
  raise newException(ERuntimeError, "Error: Unable to remove variable, it doesn't exist.")

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
      of nnkCommand, nnkVarDeclar, nnkFunc:
        # Commands are not allowed in Lists.
        if item.kind == nnkListLit:
          raise newException(ERuntimeError, "Error: $1 not allowed in a list literal" % [$node.kind])
        elif item.kind == nnkQuotLit:
          if node.kind == nnkCommand:
            result.lValue.add(newCmnd(node.value))
          elif node.kind == nnkVarDeclar or node.kind == nnkFunc:
            result.lValue.add(newASTNode(node))
          
      of nnkIntLit, nnkStringLit, nnkFloatLit, nnkListLit, nnkQuotLit:
        result.lValue.add(toPType(node))

proc command*(cmnd: string, dataStack: var TStack, vars, gvars: var PType) # from core.nim
proc interpretQuotation*(quot: PType, dataStack: var TStack, vars, gvars: var PType) # from core.nim

proc interpret*(ast: seq[PNaelNode], dataStack: var TStack, vars, gvars: var PType) =
  for node in items(ast):
    case node.kind
    of nnkCommand:
      command(node.value, dataStack, vars, gvars)
    of nnkIntLit, nnkStringLit, nnkFloatLit, nnkListLit, nnkQuotLit:
      dataStack.push(toPType(node))
    of nnkVarDeclar:
      vars.declVar(node.value)
    of nnkFunc:
      if gvars.getVarIndex(node.fName) == -1:
        gvars.declVar(node.fName)
      gvars.setVar(node.fName, newFunc(node))

include core

proc exec*(code: string, dataStack: var TStack, vars, gvars: var PType) =
  var ast = parse(code)
  interpret(ast, dataStack, vars, vars)

var dataStack = newStack(200)
var vars = newVariables() # 'main' variables(They act as both local and global)
vars.addStandard()

when isMainModule:
  var t = getStartmilsecs()
  var ast = parse("x let, x 5 5 + = x")
  interpret(ast, dataStack, vars, vars)
  printStack(dataStack)
  echo("Time taken, ", getStartmilsecs() - t)