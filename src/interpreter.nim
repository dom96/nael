# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# Interpreter - Executes the AST
import unity, core

var dataStack = newStack(200)
var vars = newVariables()

proc interpret*(ast: seq[PNaelNode]) =
  for node in items(ast):
    case node.kind
    of nnkCommand:
      command(node, dataStack, vars)
    of nnkIntLit:
      dataStack.push(newInt(node.iValue))
    else:
      #
      
when isMainModule:
  var ast = parse("5 print")
  interpret(ast)