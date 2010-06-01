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
    
    if tVar.kind != ntFunc:
      dataStack.push(tVar)
    else:
      var localVars = newVariables() # This functions local variables
      var funcStack = newStack(200) # This functions stack
      
      for arg in items(tVar.args):
        if arg.kind == ntCmnd:
          var first = dataStack.pop()
          localVars.declVar(arg.value)
          localVars.setVar(arg.value, first)
        else:
          raise newException(ERuntimeError, "Error: Function contains unexpected args, " & $arg.kind)
      
      interpretQuotation(tVar.quot, funcStack, localVars, gvars)
    


proc interpretQuotation*(quot: PType, dataStack: var TStack, vars, gvars: var PType) =
  if quot.kind != ntQuot:
    raise newException(EInvalidValue, "Error: Argument given is not a quotation")
  
  for item in items(quot.lvalue):
    case item.kind
    of ntInt, ntFloat, ntString, ntList, ntQuot, ntDict, ntNil, ntFunc:
      dataStack.push(item)
    of ntCmnd:
      command(item.value, dataStack, vars, gvars)
    of ntAstNode:
      case item.node.kind:
      of nnkVarDeclar:
        vars.declVar(item.node.value)
      of nnkVarSet:
        vars.setVar(item.node.name, toPType(item.node.setValue))
      of nnkFunc:
        gvars.declVar(item.node.fName)
        gvars.setVar(item.node.fName, newFunc(item.node))
      else:
        raise newException(ERuntimeError, "Error: Unexpected AstNode in quotation, " & $item.node.kind)

proc loadModules(modules: seq[string], vars, gvars: var PType) =
  var paths = gvars.getVar("__path__")
  var modulesVar = gvars.getVar("__modules__")
  if paths != nil and modulesVar != nil:
    for path in items(paths.lValue):
      if path.kind == ntString:
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
            modulesVar.lValue.add(moduleList)
          else:
            raise newException(ERuntimeError, "Error: Unable to load " & module & ", module cannot be found.")
      else:
        raise newException(ERuntimeError, "Error: Unable to load module, incorrect path, got type " & $path.kind)

  else:
    raise newException(ERuntimeError, "Error: Unable to load module, path and/or modules variable is not declared.")


