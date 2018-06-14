# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# Interpreter - Executes the AST
import parser, strutils, os, times, math, dynlib

type
  TDict* = seq[tuple[name: string, value: PType]]

  TTypes* = enum
    ntInt,
    ntFloat,
    ntFraction,
    ntString,
    ntBool,
    ntList,
    ntQuot,
    ntDict,
    ntNil,
    ntCmnd, # Exclusive to quotations.
    ntVar, # A pointer to a variable
    ntFunc, # Exclusively used only in variables
    ntASTNode, # A PNaelNode - VarDeclar etc, Are declared with this in quotations
    ntType, # Stores type information
    ntObject
    
  PType* = ref TType
  TType* = object
    case kind*: TTypes
    of ntInt:
      iValue*: int64
    of ntFloat:
      fValue*: float64
    of ntFraction:
      firstVal*: int64
      secondVal*: int64
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
      val*: PType
    of ntType:
      name*: string
      fields*: seq[string]
    of ntObject:
      typ*: PType # the ntType
      oFields*: TDict
      
  TStack* = tuple[stack: seq[PType], limit: int]
  
  RuntimeError* = object of Exception
  
# Characters that are invalid in variable names
var invalidVars = {'(', ')', '[', ']', '{', '}', '\"', '\''}

var currentLine = 0 # The line number of the code being executed
var currentChar = 0 # The char number of the code being executed

proc errorLine(): string =
  result = "[$1, $2] " % [$currentLine, $currentChar]

# Stack
proc toString*(item: PType, stack = false): string =
  result = ""

  case item.kind
  of ntInt:
    return $item.iValue
  of ntFloat:
    return $item.fValue
  of ntFraction:
    return $item.firstVal & "/" & $item.secondVal
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
      result.add(toString(item.lValue[i], stack))
      if i < len(item.lValue)-1:
        result.add(", ")
    result.add("]")
      
  of ntQuot:
    result.add("(")
    for i in 0 .. len(item.lValue)-1:
      result.add(toString(item.lValue[i], stack))
      if i < len(item.lValue)-1:
        result.add(", ")
    result.add(")")
  of ntDict:
    result.add("__dict__")
  of ntNil:
    result.add("nil")
  of ntVar:
    result.add("<var '" & item.vvalue & "' loc=" & $item.loc & " val=" & toString(item.val) & ">")
  of ntFunc:
    result.add("__func__")
  of ntAstNode:
    case item.node.kind:
    of nnkVarDeclar:
      result.add(item.node.value & " let")
    of nnkFunc:
      result.add("Func(" & item.node.fName & ")")
    else:
      raise newException(RuntimeError, errorLine() & "Error: Unexpected AstNode in `$`, " & $item.node.kind)
  of ntType:
    result.add("<type '" & item.name & "'>")
  of ntObject:
    result.add("<object " & toString(item.typ) & ">")

proc `$`*(kind: TTypes): string =
  case kind
  of ntInt: return "int"
  of ntFloat: return "float"
  of ntFraction: return "fraction"
  of ntString: return "string"
  of ntBool: return "bool"
  of ntList: return "list"
  of ntQuot: return "quot"
  of ntDict: return "dict"
  of ntNil: return "nil"
  of ntCmnd: return "__cmnd__"
  of ntVar: return "var"
  of ntFunc: return "__func__"
  of ntASTNode: return "__ASTNode__"
  of ntType: return "type"
  of ntObject: return "object"

proc isEqual*(first, second: PType): bool =
  if first.kind == second.kind:
    case first.kind
    of ntInt:
      return first.iValue == second.iValue
    of ntFloat:
      return first.fValue == second.fValue
    of ntFraction:
      return first.firstVal == second.firstVal and first.secondVal == second.secondVal
    of ntString, ntCmnd, ntVar:
      return first.value == second.value
    of ntBool:
      return first.bValue == second.bValue
    of ntList, ntQuot:
      if len(first.lValue) == len(second.lValue):
        for i in 0 .. len(first.lValue)-1:
          if not isEqual(first.lValue[i], second.lValue[i]):
            return false
        return true
      else: return false
    of ntDict, ntFunc, ntAstNode, ntType, ntObject:
      return first == second # FIXME: This probably doesn't work.
    of ntNil: return true
  else: return false

proc printStack*(stack: TStack) =
  if stack.stack.len() > 0:
    var result = "stack → ["
    for i in 0 .. len(stack.stack)-1:
      result.add(toString(stack.stack[i], true))
      if i < len(stack.stack)-1:
        result.add(", ")
      
    result.add("]")
    echo(result)  

proc newStack*(limit: int): TStack =
  result.stack = @[]
  result.limit = limit

proc push*(stack: var TStack, item: PType) =
  if stack.stack.len() >= stack.limit:
    raise newException(OverflowError, errorLine() & "Error: Stack overflow")
    
  stack.stack.add(item)

proc pop*(stack: var TStack): PType =
  if stack.stack.len() < 1:
    raise newException(OverflowError, errorLine() & "Error: Stack underflow")
    
  return stack.stack.pop()

proc newInt*(value: int64): PType =
  new(result)
  result.kind = ntInt
  result.iValue = value
  
proc newFloat*(value: float64): PType =
  new(result)
  result.kind = ntFloat
  result.fValue = value

proc newFraction*(fValue: int64, sValue: int64): PType =
  new(result)
  result.kind = ntFraction
  result.firstVal = fValue
  result.secondVal = sValue

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
      raise newException(RuntimeError, errorLine() &
          "Error: Function declaration incorrect, got " & $n.kind & " for args")

  result.args = args
  result.quot = toPType(node.quot)

proc newType*(node: PNaelNode): PType =
  new(result)
  result.kind = ntType
  result.name = node.tName
  
  var fields: seq[string] = @[]
  for n in items(node.fields.children):
    if n.kind == nnkCommand:
      fields.add(n.value)
    else:
      raise newException(RuntimeError, errorLine() &
          "Error: Tuple declaration incorrect, got " & $n.kind & " for fields")

  result.fields = fields

proc newObject*(typ: PType, fields: TDict): PType =
  new(result)
  result.kind = ntObject
  result.typ = typ
  result.oFields = fields

proc newVar*(name: string, loc: int, val: PType): PType =
  new(result)
  result.kind = ntVar
  result.vvalue = name
  result.loc = loc
  result.val = val

proc newASTNode*(node: PNaelNode): PType = 
  new(result)
  result.kind = ntASTNode
  result.node = node

proc newNil*(): PType =
  new(result)
  result.kind = ntNil

proc newVariables*(): PType =
  new(result)
  result.kind = ntDict
  result.dValue = @[]

proc includeModules(modules: seq[string], dataStack: var TStack, vars, gvars: var PType)
proc addStandard*(vars: var PType) =
  ## Adds standard variables(__path__, __modules__) to vars. 
  var appDir = newString(os.getAppDir())
  var pathVar = newList(@[appDir, newString(appDir.value / "lib")])
  vars.dValue.add(("__path__", pathVar))
  
  var modulesVar: PType # [["name", {locals}, {globals}], ...]
  modulesVar = newList(@[])
  vars.dValue.add(("__modules__", modulesVar))
  
  vars.dValue.add(("false", newBool(false)))
  vars.dValue.add(("true", newBool(true)))

proc loadStdlib*(dataStack: var TStack, vars, gvars: var PType) =
  # Load the system module
  includeModules(@["system"], dataStack, vars, gvars)
  
proc getVar*(vars: var PType, name: string): PType =
  if vars.kind != ntDict:
    raise newException(ValueError, errorLine() & "Error: The variable list needs to be a dict.")

  for vname, value in items(vars.dValue):
    if vname == name:
      return value
      
  return nil

proc getVarIndex*(vars: var PType, name: string): int =
  if vars.kind != ntDict:
    raise newException(ValueError, errorLine() & "Error: The variable list needs to be a dict.")

  for i in 0 .. len(vars.dValue)-1:
    if vars.dValue[i][0] == name:
      return i
      
  return -1

proc getVarField*(vars: var PType, name: string): PType = 
  var s = name.split('.')
  
  var tVar = vars.getVar(s[0])
  
  if tVar != nil:
    if tVar.kind == ntObject:
      # Check if the field exists
      for fieldName, value in items(tVar.oFields):
        if fieldName == s[1]:
          return value
          
  return nil

proc getVarFieldIndex*(vars: var PType, name: string): array[0..1, int] = # [var index, field index]
  var s = name.split('.')
  
  var tVarIndex = vars.getVarIndex(s[0])
  var tVar = vars.dValue[tVarIndex][1]
  
  if tVarIndex != -1:
    if tVar.kind == ntObject:
      # Check if the field exists
      for i in 0 .. len(tVar.oFields)-1:
        if tVar.oFields[i][0] == s[1]:
          return [tVarIndex, i]
          
  return [-1,-1]

proc declVar*(vars: var PType, name: string) =
  # Declares a variable
  for i in items(name):
    if i in invalidVars:
      raise newException(RuntimeError, errorLine() & "Error: Variable name contains illegal characters.")
  
  if vars.kind != ntDict:
    raise newException(ValueError, errorLine() & "Error: The variable list needs to be a dict.")

  if getVarIndex(vars, name) != -1:
    raise newException(RuntimeError, errorLine() & "Error: $1 is already declared." % [name])

  var theVar = newNil()

  vars.dValue.add((name, theVar))
  
proc setVar*(vars: var PType, name: string, theVar: PType) =
  # Sets a variables value.
  if vars.kind != ntDict:
    raise newException(ValueError, errorLine() & "Error: The variable list needs to be a dict.")
  
  var varIndex = vars.getVarIndex(name)
  if varIndex == -1:
    raise newException(RuntimeError, errorLine() & "Error: Variable $1 is not declared." % [name])
    
  vars.dValue[varIndex][1] = theVar

proc setVarField*(vars: var PType, name: string, theVar: PType) =
  # Sets a variables value.
  if vars.kind != ntDict:
    raise newException(ValueError, errorLine() & "Error: The variable list needs to be a dict.")
  
  var varIndex = vars.getVarFieldIndex(name)
  if varIndex[0] == -1 or varIndex[1] == -1:
    raise newException(RuntimeError, errorLine() & "Error: Variable $1 is not declared." % [name])
    
  vars.dValue[varIndex[0]][1].oFields[varIndex[1]][1] = theVar
  
proc remVar*(vars: var PType, name: string) =
  if vars.kind != ntDict:
    raise newException(ValueError, errorLine() & "Error: The variable list needs to be a dict.")

  for i in 0 .. len(vars.dValue)-1:
    if vars.dValue[i][0] == name:
      vars.dValue.del(i)
      return
      
  raise newException(RuntimeError, errorLine() & "Error: Unable to remove variable, it doesn't exist.")

proc copyVar*(tVar: PType): PType =
  new(result)
  result.kind = tVar.kind
  case tVar.kind
  of ntList:
    result.lValue = @[]
    for i in 0 .. len(tVar.lValue)-1:
      result.lValue.add(tVar.lValue[i])
  of ntQuot:
    result.lValue = @[]
    for i in 0 .. len(tVar.lValue)-1:
      result.lValue.add(tVar.lValue[i])
  of ntDict:
    result.dValue = @[]
    for i in 0 .. len(tVar.dValue)-1:
      result.dValue.add(tVar.dValue[i])
  of ntVar:
    result.vvalue = tVar.vvalue
    result.loc = tVar.loc
    result.val = tVar.val
  of ntFunc:
    result.args = tVar.args
    result.quot = tVar.quot # I doubt there will be any functions for editing this
  of ntAstNode, ntType, ntInt, ntFloat, ntFraction, ntCmnd, ntString, ntBool, ntNil:
    result = tVar
  of ntObject:
    result.typ = tVar.typ
    result.oFields = tVar.oFields
    
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
    raise newException(SystemError, errorLine() & "Error: Unexpected nael node kind, " & $item.kind)
  
  # Add all the children of quotations and lists.
  if item.kind == nnkListLit or item.kind == nnkQuotLit:
    for node in items(item.children):
      case node.kind
      of nnkCommand, nnkVarDeclar, nnkFunc, nnkTuple:
        # Commands are not allowed in Lists.
        if item.kind == nnkListLit:
          raise newException(RuntimeError, errorLine() &
              "Error: $1 not allowed in a list literal" % [$node.kind])
        
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
  # Reset the values
  currentLine = 0
  currentChar = 0
  for node in items(ast):
    # Set these before any execution begins,
    # so that when errors occur they get the right info.
    currentLine = node.lineNum
    currentChar = node.charNum
  
    # REMEMBER ANY CHANGES YOU MAKE HERE, HAVE TO BE MADE IN interpretQuotation
    case node.kind
    of nnkCommand:
      command(node.value, dataStack, vars, gvars)
    of nnkIntLit, nnkStringLit, nnkFloatLit, nnkListLit, nnkQuotLit:
      dataStack.push(toPType(node))
    of nnkVarDeclar:
      if gvars.getVar(node.value) != nil:
        raise newException(RuntimeError, errorLine() &
            "Error: $1 is already declared as a global variable" % [node.value])
      else:
        vars.declVar(node.value)
    of nnkFunc:
      if gvars.getVarIndex(node.fName) == -1:
        gvars.declVar(node.fName)
      gvars.setVar(node.fName, newFunc(node))
    of nnkTuple:
      if gvars.getVarIndex(node.tName) == -1:
        gvars.declVar(node.tName)
      gvars.setVar(node.tName, newType(node))

include core

proc exec*(code: string, dataStack: var TStack, vars, gvars: var PType) =
  var ast = parse(code)
  interpret(ast, dataStack, vars, vars)

var dataStack = newStack(200)
var vars = newVariables() # 'main' variables(They act as both local and global)
vars.addStandard()
loadStdlib(dataStack, vars, vars)

when isMainModule:
  var t = getStartmilsecs()
  var ast = parse("x let, x 5 5 + = x")
  interpret(ast, dataStack, vars, vars)
  printStack(dataStack)
  echo("Time taken, ", getStartmilsecs() - t)
