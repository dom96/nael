# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 31 May 2010

# core - Implements commands like 'print'

proc interpretQuotation*(quot: PType, dataStack: var TStack, vars, gvars: var PType)
proc loadModules(modules: seq[string], vars, gvars: var PType)

proc command*(cmnd: string, dataStack: var TStack, vars, gvars: var PType) =
  case cmnd
  of "print":
    var first = dataStack.pop()
    echo($first)
  of "call":
    var first = dataStack.pop()
    interpretQuotation(first, dataStack, vars, gvars)
  of "import":
    var first = dataStack.pop()
    if first.kind == ntString:
      loadModules(@[first.value], vars, gvars)
      

    
  else:
    var tVar = vars.getVar(cmnd)
    if tVar == nil:
      raise newException(EVar, "Error: $1 is not declared.")
    dataStack.push(tVar)
    
    # TODO: Functions

proc interpretQuotation*(quot: PType, dataStack: var TStack, vars, gvars: var PType) =
  if quot.kind != ntQuot:
    raise newException(EInvalidValue, "Error: Argument given is not a quotation")
  
  for item in items(quot.lvalue):
    case item.kind
    of ntInt, ntFloat, ntString, ntList, ntQuot, ntDict, ntNil:
      dataStack.push(item)
    of ntCmnd:
      command(item.value, dataStack, vars, gvars)

proc loadModules(modules: seq[string], vars, gvars: var PType) =
  var paths = gvars.getVar("__path__")
  if paths != nil:
    for path in items(paths.lValue):
      for module in items(modules):
        var file = readFile(path.value / module & ".nael")
        if file != nil:
          var locals = newVariables()
          var globals = newVariables()
          globals.addStandard()
          var moduleStack = newStack(200)
          
          var ast = parse(file)
          interpret(ast, moduleStack, locals, globals)
          
          var moduleList = newList(@[newString(module), locals, globals]) # [name, {locals}, {globals}]
          var modulesVar = gvars.getVar("__modules__")
          modulesVar.lValue.add(moduleList)
        else:
          echo("File not found.. ", path.value / module & ".nael")
