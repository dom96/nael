# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 31 May 2010

# core - Implements commands like 'print'

proc getModule(name: string, gvars: var PType): seq[PType]
proc loadModules(modules: seq[string], vars, gvars: var PType)
proc includeModules(modules: seq[string], dataStack: var TStack, vars, gvars: var PType)

proc invalidTypeErr(got, expected, function: string): ref ERuntimeError =
  return newException(ERuntimeError, errorLine() & "Error: Invalid types, $1 expects $2, got $3" % [function, expected, got])

proc command*(cmnd: string, dataStack: var TStack, vars, gvars: var PType) =
  case cmnd
  of "print":
    var first = dataStack.pop()
    echo(toString(first))
    
  of "call":
    var first = dataStack.pop()
    if first.kind == ntQuot:
      interpretQuotation(first, dataStack, vars, gvars)
    else:
      raise invalidTypeErr($first.kind, "quot", "call")
      
  of "import":
    var first = dataStack.pop()
    if first.kind == ntString:
      loadModules(@[first.value], vars, gvars)
    elif first.kind == ntList:
      var modList: seq[string] = @[]
      for i in items(first.lValue):
        if i.kind == ntString:
          modList.add(i.value)
        else:
          raise invalidTypeErr($i.kind, "string", "call")
    
      loadModules(modList, vars, gvars)
    else:
      raise invalidTypeErr($first.kind, "string or list", "call")
      
  of "include":
    var first = dataStack.pop()
    if first.kind == ntString:
      includeModules(@[first.value], dataStack, vars, gvars)
    elif first.kind == ntList:
      var modList: seq[string] = @[]
      for i in items(first.lValue):
        if i.kind == ntString:
          modList.add(i.value)
        else:
          raise invalidTypeErr($i.kind, "string", "call")
    
      includeModules(modList, dataStack, vars, gvars)
    else:
      raise invalidTypeErr($first.kind, "string or list", "call")
    
  of "+", "-", "*", "/":
    var first = datastack.pop()
    var second = datastack.pop()
  
    if cmnd == "+":
      if first.kind == ntInt and second.kind == ntInt:
        dataStack.push(newInt(second.iValue + first.iValue))
      elif first.kind == ntString and second.kind == ntString:
        dataStack.push(newString(second.value & first.value))
      elif first.kind == ntFloat and second.kind == ntFloat:
        dataStack.push(newFloat(second.fvalue + first.fvalue))
      elif first.kind == ntInt and second.kind == ntFloat:
        dataStack.push(newFloat(second.fvalue + float(first.ivalue)))
      elif first.kind == ntFloat and second.kind == ntInt:
        dataStack.push(newFloat(float(second.ivalue) + first.fvalue))
      else:
        raise invalidTypeErr($first.kind & " and " &
            $second.kind, "[string, string], [int, int], [float, float] or [float, int]", "+")
        
    elif cmnd == "-":
      if first.kind == ntInt and second.kind == ntInt:
        dataStack.push(newInt(second.iValue - first.iValue))
      elif first.kind == ntFloat and second.kind == ntFloat:
        dataStack.push(newFloat(second.fvalue - first.fvalue))
      else:
        raise invalidTypeErr($first.kind & " and " &
            $second.kind, "int, int or float, float", "-")
        
    elif cmnd == "*":
      if first.kind == ntInt and second.kind == ntInt:
        dataStack.push(newInt(second.iValue * first.iValue))
      elif first.kind == ntFloat and second.kind == ntFloat:
        dataStack.push(newFloat(second.fvalue * first.fvalue))
      else:
        raise invalidTypeErr($first.kind & " and " &
            $second.kind, "int, int or float, float", "*")
                        
    elif cmnd == "/":
      if first.kind == ntInt and second.kind == ntInt:
        dataStack.push(newInt(second.iValue div first.iValue))
      elif first.kind == ntFloat and second.kind == ntFloat:
        dataStack.push(newFloat(second.fvalue / first.fvalue))
      else:
        raise invalidTypeErr($first.kind & " and " &
          $second.kind, "int, int or float, float", "/")
  
  of "!":
    # Negate a boolean
    var first = dataStack.pop()
    if first.kind == ntBool:
      dataStack.push(newBool(not first.bValue))
    else:
      raise invalidTypeErr($first.kind, "bool", "!")
  
  of "if":
    # Depending on a boolean on the stack, executes a particular quotation
    # (cond) (then) (else) if
    var theElse = datastack.pop()
    var then = datastack.pop()
    var cond = datastack.pop()
    
    if cond.kind == ntQuot and theElse.kind == ntQuot and then.kind == ntQuot:
      interpretQuotation(cond, dataStack, vars, gvars)
      var boolean = dataStack.pop()
      if boolean.kind != ntBool:
        raise invalidTypeErr($boolean.kind, "bool", "if")
      
      if boolean.bValue:
        interpretQuotation(then, dataStack, vars, gvars)
      else:
        interpretQuotation(theElse, dataStack, vars, gvars)
    else:
      raise invalidTypeErr($cond.kind & ", " & $theElse.kind & " and " & $then.kind,
              "quot, quot, quot", "if")     
  
  of "while":
    # Loop until cond becomes false
    # (cond) (do) while
    var do = dataStack.pop()
    var cond = dataStack.pop()
    
    if do.kind == ntQuot and cond.kind == ntQuot:
      interpretQuotation(cond, dataStack, vars, gvars)
      var boolean = dataStack.pop()
      if boolean.kind != ntBool:
        raise invalidTypeErr($boolean.kind, "bool", "while")
  
      while boolean.bValue:
        interpretQuotation(cond, dataStack, vars, gvars)
        boolean = dataStack.pop()
        
        interpretQuotation(do, dataStack, vars, gvars)
  
  of "==":
    var first = dataStack.pop()
    var second = dataStack.pop()
    
    dataStack.push(newBool(isEqual(first, second)))
  
  of "=":
    var first = dataStack.pop()
    var second = dataStack.pop()
    
    if second.kind == ntVar:
      if second.loc == 1:
        gvars.setVar(second.vvalue, first)
      elif second.loc == 0:
        vars.setVar(second.vvalue, first)
    else:
      raise invalidTypeErr($second.kind, "var", "=")
  
  of "get":
    var first = dataStack.pop()
    if first.kind == ntVar:
      var tVar: PType
      
      if first.loc == 0:
        tVar = vars.getVar(first.vvalue)
      elif first.loc == 1:
        tVar = gvars.getVar(first.vvalue)
      else:
        raise newException(ERuntimeError, errorLine() &
            "Error: Variable's location is incorrect, got $1" % [$first.loc])
      
      if tVar == nil:
        raise newException(ERuntimeError, errorLine() &
            "Error: $1 is not declared." % [first.vvalue])
      
      dataStack.push(tVar)
    
    else:
      raise invalidTypeErr($first.kind, "var", "get")
  
  of "del":
    var v = dataStack.pop()
    if v.kind == ntVar:
      if v.loc == 0:
        vars.remVar(v.vvalue)
      elif v.loc == 1:
        gvars.remVar(v.vvalue)
    
  of "__stack__":
    dataStack.push(newList(dataStack.stack))
    
  of "swap":
    # [1, 2] -> [2, 1]
    var first = dataStack.pop()
    var second = dataStack.pop()
    dataStack.push(first)
    dataStack.push(second)
  
    # List manipulators
  of "nth":
    # [list] 5 nth
    # Gets the 5th item of list
    var index = dataStack.pop()
    var list = dataStack.pop()
    if index.kind == ntInt and list.kind == ntlist:
      # WTF, something is really wrong with exceptions
      #try:
      dataStack.push(list.lValue[int(index.iValue)])
      #except:
      #  raise newException(ERuntimeError, "Error: $1" % [getCurrentExceptionMsg()])
    else:
      raise invalidTypeErr($index.kind & " and " & $list.kind, "int and list", "nth")
  
  of "len":
    # Pushes the length of a list or string
    var list = dataStack.pop()
    if list.kind == ntList:
      dataStack.push(newInt(list.lValue.len()))
    elif list.kind == ntString:
      dataStack.push(newInt(list.value.len()))
    else:
      raise invalidTypeErr($list.kind, "list or string", "len")

  of "append":
    # [list] 5 append
    # Appends a value to a list
    var value = dataStack.pop()
    var list = dataStack.pop()
    if list.kind == ntList:
      list.lValue.add(value)
      dataStack.push(list)
    else:
      raise invalidTypeErr($list.kind, "list", "append")

    # Math
  of "sqrt":
    var first = dataStack.pop()
    if first.kind == ntFloat:
      dataStack.push(newFloat(sqrt(first.fValue)))
    else:
      raise invalidTypeErr($first.kind, "float", "sqrt")
  
  of "pow":
    var first = dataStack.pop()
    var second = dataStack.pop()
    if first.kind == ntFloat and second.kind == ntFloat:
      dataStack.push(newFloat(pow(second.fValue, first.fValue)))
    else:
      raise invalidTypeErr($first.kind & " and " & $second.kind, "float and float", "pow")
  
  else:
    # Variables and Functions
    var tVar: PType
    var varLoc: int = -1 # 0 for local, 1 for global
    var module: seq[PType]
    
    if not ("." in cmnd):
      tVar = vars.getVar(cmnd)
      varLoc = 0
      if tVar == nil:
        tVar = gvars.getVar(cmnd)
        varLoc = 1
    else:
      # cmnd contains a dot
      var before = cmnd.split('.')[0]
      var after = cmnd.split('.')[1]
      
      module = getModule(before, gvars) # [name, {locals}, {globals}]
      if module == nil:
        tVar = nil
      else:
        tVar = module[2].getVar(after)
        varLoc = 1
    
    if tVar == nil:
      raise newException(ERuntimeError, errorLine() & "Error: $1 is not declared." % [cmnd])
    
    if tVar.kind != ntFunc:
      dataStack.push(newVar(cmnd, varLoc))
    else:
      # Function call - Functions don't share scope, but they share the stack.
      # TODO: Perhaps make a 'callFunc' function 
      
      var localVars = newVariables() # This functions local variables
      var globalVars = newVariables() # This functions global variables
      # Copy the current gvars to this functions globalVars
      if module == nil:
        globalVars.dValue = gvars.dValue
      else:
        globalVars.dValue = module[2].dValue
      
      # Add the arguments in reverse, so that the 'nael rule' applies
      # 5 6 foo -> foo(5,6)
      # I have to add the args to globals, so that functions called from this function
      # that have a quotation passed to them(with one of the var args..) works
      # Look at tests/funcargs.nael for more info

      for i in countdown(tVar.args.len()-1, 0):
        var arg = tVar.args[i]
        if arg.kind == ntCmnd:
          #try:
          var first = dataStack.pop()
          globalVars.declVar(arg.value)
          globalVars.setVar(arg.value, first)
              
          #except EOverflow:
          #  # TODO: Check if this works, After araq fixes the exception bug
          #  raise newException(ERuntimeError, 
          #          "Error: $1 expects $2 args, got $3" %
          #                  [cmnd, $(tVar.args.len()-1), $(i)])

        else:
          raise newException(ERuntimeError, errorLine() & "Error: " & cmnd &
                  " contains unexpected args, of kind " & $arg.kind)
                  
      
      interpretQuotation(tVar.quot, dataStack, localVars, globalVars)

      # TODO: Move the variables that were declared global in that function
      # to gvars

      discard """
      # Now we need to delete these args...
      for i in 0 .. tVar.args.len()-1:
        echo(i, " ", tVar.args[i].value)
        if modulegvars == nil:
          gvars.remVar(tVar.args[i].value)
        else:
          modulegvars.remVar(tVar.args[i].value)"""

proc interpretQuotation*(quot: PType, dataStack: var TStack, vars, gvars: var PType) =
  if quot.kind != ntQuot:
    raise newException(EInvalidValue, errorLine() & 
        "Error: Argument given is not a quotation")
  
  for item in items(quot.lvalue):
    case item.kind
    of ntInt, ntFloat, ntString, ntBool, ntList, ntQuot, ntDict, ntNil, ntFunc, ntVar:
      dataStack.push(item)
    of ntCmnd:
      command(item.value, dataStack, vars, gvars)
    of ntAstNode:
      case item.node.kind:
      of nnkVarDeclar:
        vars.declVar(item.node.value)
      of nnkFunc:
        if gvars.getVarIndex(item.node.fname) == -1:
          gvars.declVar(item.node.fName)
        gvars.setVar(item.node.fName, newFunc(item.node))
      else:
        raise newException(ERuntimeError, errorLine() & 
            "Error: Unexpected AstNode in quotation, " & $item.node.kind)

proc getModule(name: string, gvars: var PType): seq[PType] =
  var modulesVar = gvars.getVar("__modules__")
  for module in items(modulesVar.lValue):
    if module.kind == ntList:
      if module.lValue[0].kind == ntString:
        if module.lValue[0].value == name:
          return module.lValue
      else:
        raise newException(ERuntimeError, errorLine() & 
            "Error: Invalid type, expected ntString got " &
                $module.lValue[0].kind)
      
  return nil

proc loadModules(modules: seq[string], vars, gvars: var PType) =
  var paths = gvars.getVar("__path__")
  var modulesVar = gvars.getVar("__modules__")
  if paths != nil and modulesVar != nil:
    for module in items(modules):
      # Check if the module exists
      if getModule(module, gvars) != nil:
        raise newException(ERuntimeError, errorLine() & "Error: Unable to load " &
            module & ", module is already loaded.")
    
      for path in items(paths.lValue):
        if path.kind == ntString:
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
            raise newException(ERuntimeError, errorLine() & 
                "Error: Unable to load " & module & ", module cannot be found.")
        else:
          raise newException(ERuntimeError, errorLine() &
              "Error: Unable to load " & module &
                  ", incorrect path, got type " & $path.kind)

  else:
    raise newException(ERuntimeError, errorLine() & 
        "Error: Unable to load module, path and/or modules variable is not declared.")
    
proc includeModules(modules: seq[string], dataStack: var TStack, vars, gvars: var PType) =
  var paths = gvars.getVar("__path__")
  var modulesVar = gvars.getVar("__modules__")
  if paths != nil and modulesVar != nil:
    for module in items(modules):
      for path in items(paths.lValue):
        if path.kind == ntString:
          var file = readFile(path.value / module & ".nael")
          if file != nil:
            var ast = parse(file)
            interpret(ast, dataStack, vars, gvars)
          else:
            raise newException(ERuntimeError, errorLine() &
                "Error: Unable to load " & module & ", module cannot be found.")
        else:
          raise newException(ERuntimeError, errorLine() & 
              "Error: Unable to load " & module &
                  ", incorrect path, got type " & $path.kind)

  else:
    raise newException(ERuntimeError, errorLine() & 
        "Error: Unable to load module, path and/or modules variable is not declared.")


