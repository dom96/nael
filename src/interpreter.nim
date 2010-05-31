# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# Interpreter - Executes the AST
import unity, core

type
  ERuntimeError* = object of EBase

var dataStack = newStack(200)
var vars = newVariables()

proc toList(list: PNaelNode): PType =
  ## Converts a PNaelNode of kind, quotation or list. Into a corresponding
  ## PType
  new(result)
  if list.kind == nnkListLit:
    result.kind = ntList
    result.lValue = @[]
    
  elif list.kind == nnkQuotLit:
    result.kind = ntQuot
    result.lValue = @[]
    
  for node in items(list.children):
    case node.kind
    of nnkCommand:
      # Commands are not allowed in Lists.
      if list.kind == nnkListLit:
        raise newException(ERuntimeError, "Error: Command literal not allowed in a list literal")
      elif list.kind == nnkQuotLit:
        result.lValue.add(newCmnd(node.value))
    of nnkIntLit:
      result.lValue.add(newInt(node.iValue))
    of nnkStringLit:
      result.lValue.add(newString(node.value))
    of nnkFloatLit:
      result.lValue.add(newFloat(node.fValue))
    of nnkListLit:
      result.lValue.add(toList(node))
    of nnkQuotLit:
      result.lValue.add(toList(node))
    else:
      nil #TODO

proc interpret*(ast: seq[PNaelNode]) =
  for node in items(ast):
    case node.kind
    of nnkCommand:
      command(node, dataStack, vars)
    of nnkIntLit:
      dataStack.push(newInt(node.iValue))
    of nnkStringLit:
      dataStack.push(newString(node.value))
    of nnkFloatLit:
      dataStack.push(newFloat(node.fValue))
    of nnkListLit:
      dataStack.push(toList(node))
    of nnkQuotLit:
      dataStack.push(toList(node))
    else:
      #
      
when isMainModule:
  var ast = parse("(5 6 7 [234 6.98] print) print")
  interpret(ast)