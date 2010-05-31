# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# Interpreter - Executes the AST
import parser, stack, variables

var dStack = newStack(200)
var vars = newVariables()

proc interpret*(ast: seq[PNaelNode]) =
  for node in items(ast):
    case node.kind
    of nnkIntLit:
      # TODO