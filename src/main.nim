# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 30 May 2010

# REPL - A nice REPL for nael.
import interpreter, os

when isMainModule:
  if paramCount() == 0 or paramCount() == -1:
    var dataStack = newStack(200)
    var vars = newVariables() # 'main' variables(They act as both local and global)
    vars.addStandard()

    while True:
      stdout.write(">> ")
      try:
        exec(stdin.readLine(), dataStack, vars, vars)
      except ERuntimeError, EOverflow, EInvalidValue:
        echo(getCurrentExceptionMsg())
        
      printStack(dataStack)
  else:
    if paramStr(1) == "-a" or paramStr(1) == "--about":
      echo("   nael interpreter v0.1")
      echo("   ---------------------")
      echo("http://github.com/dom96/nael")
      echo("For license read license.txt")
      discard stdin.readLine()
        
    elif paramStr(1) == "-h" or paramStr(1) == "--help" or paramCount() > 0:
      echo("nael               Interpreter")
      echo("nael -noDecoration Starts the interpreter, without >>")
      echo("nael -h[--help]    This help message")
      echo("nael -a[--about]   About")
      
