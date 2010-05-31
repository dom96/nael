# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# Interpreter - Executes the AST
import unity, core, strutils

type
  ERuntimeError* = object of EBase

var dataStack = newStack(200)
var vars = newVariables() # global variables

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

proc interpret*(ast: seq[PNaelNode]) =
  for node in items(ast):
    case node.kind
    of nnkCommand:
      command(node.value, dataStack, vars)
    of nnkIntLit, nnkStringLit, nnkFloatLit, nnkListLit, nnkQuotLit:
      dataStack.push(toPType(node))
    of nnkVarDeclar:
      vars.declVar(node.value)
    of nnkVarSet:
      vars.setVar(node.name, toPType(node.setValue)) 
    
    else:
      #
      
when isMainModule:
  var ast = parse("x let, x \"hai\" =, x print")
  interpret(ast)
  
  if dataStack.stack.len() > 0:
    var result = "stack["
    for i in items(dataStack.stack):
      result.add($i & ", ")
    result.add("]")
    echo(result)