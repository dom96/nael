# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 31 May 2010

# core - Implements commands like 'print'
import unity

proc command*(node: PNaelNode, dataStack: var TStack, vars: var PType) =
  case node.value
  of "print":
    var first = dataStack.pop()
    echo($first)