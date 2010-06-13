# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 31 May 2010

# core - Implements commands like 'print'

proc getModule(name: string, gvars: var PType): seq[PType]
proc loadModules(modules: seq[string], vars, gvars: var PType)
proc callFunc*(dataStack: var TStack, vars, gvars: var PType, cmnd: string,
    tVar: PType, module: var seq[PType])

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
  
  of "ccall":
    # "header" "function" [args] ccall
    var args = dataStack.pop()
    var function = dataStack.pop()
    var header = dataStack.pop()
    if function.kind == ntString and header.kind == ntString and args.kind == ntList:
      dataStack.push(newString("Sorry this doesn't work yet :("))
      when False:
        var lib = LoadLib(header.value)
        var funcPtr = checkedSymAddr(lib, function.value)
        var func = cast[proc(x: float): float](funcPtr)
        var arg = 4.5
        echo(cast[int](addr(arg)))
        var val = func(arg)
        echo(val)
    else:
      raise invalidTypeErr($args.kind & $function.kind & $header.kind, "list, string and string", "ccall")
      
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
    
  of "+", "-", "*", "/", "%":
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
  
    elif cmnd == "%":
      if first.kind == ntInt and second.kind == ntInt:
        dataStack.push(newInt(second.iValue %% first.iValue))
      else:
        raise invalidTypeErr($first.kind & " and " &
          $second.kind, "int, int", "%")
  
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
        interpretQuotation(do, dataStack, vars, gvars)

        interpretQuotation(cond, dataStack, vars, gvars)
        boolean = dataStack.pop()
    else:
      raise invalidTypeErr($do.kind & " and " & $cond.kind, "quot and quot", "while")
  
  of "==":
    var first = dataStack.pop()
    var second = dataStack.pop()
    
    dataStack.push(newBool(isEqual(first, second)))
  
  of ">":
    var first = dataStack.pop()
    var second = dataStack.pop()
    
    if first.kind == ntInt and second.kind == ntInt:
      dataStack.push(newBool(second.iValue > first.iValue))
    elif first.kind == ntFloat and second.kind == ntFloat:
      dataStack.push(newBool(second.fValue > first.fValue))
    else:
      raise invalidTypeErr($first.kind & " and " & $second.kind, "int, int or float, float", ">")

  of "<":
    var first = dataStack.pop()
    var second = dataStack.pop()
    
    if first.kind == ntInt and second.kind == ntInt:
      dataStack.push(newBool(second.iValue < first.iValue))
    elif first.kind == ntFloat and second.kind == ntFloat:
      dataStack.push(newBool(second.fValue < first.fValue))
    else:
      raise invalidTypeErr($first.kind & " and " & $second.kind, "int, int or float, float", "<")
  
  of "and":
    var first = dataStack.pop()
    var second = dataStack.pop()
    if first.kind == ntBool and second.kind == ntBool:
      dataStack.push(newBool(second.bValue and first.bValue))
    else:
      raise invalidTypeErr($first.kind & " and " & $second.kind, "bool and bool", "and")

  of "or":
    var first = dataStack.pop()
    var second = dataStack.pop()
    if first.kind == ntBool and second.kind == ntBool:
      dataStack.push(newBool(second.bValue or first.bValue))
    else:
      raise invalidTypeErr($first.kind & " and " & $second.kind, "bool and bool", "or")

  of "=":
    var first = dataStack.pop()
    var second = dataStack.pop()
    
    if second.kind == ntVar:
      if second.loc == 1:
        gvars.setVar(second.vvalue, first)
      elif second.loc == 0:
        vars.setVar(second.vvalue, first)
      elif second.loc == 2:
        vars.setVarField(second.vvalue, first)
      elif second.loc == 3:
        gvars.setVarField(second.vvalue, first)
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
      elif first.loc == 2:
        tVar = vars.getVarField(first.vvalue)
      elif first.loc == 3:
        tVar = gvars.getVarField(first.vvalue)
      else:
        raise newException(ERuntimeError, errorLine() &
            "Error: Variable's location is incorrect, got $1" % [$first.loc])
      
      if tVar == nil:
        raise newException(ERuntimeError, errorLine() &
            "Error: $1 is not declared." % [first.vvalue])
      
      # unreference the value, so that getting a list from a variable and appending
      # to it, doesn't make changes to the variable
      
      dataStack.push(copyVar(tVar))
    
    else:
      raise invalidTypeErr($first.kind, "var", "get")
  
  of "del":
    var v = dataStack.pop()
    if v.kind == ntVar:
      if v.loc == 0:
        if vars.getVar(v.vvalue) != nil:
          vars.remVar(v.vvalue)
      elif v.loc == 1:
        if gvars.getVar(v.vvalue) != nil:
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

  of "cos":
    var first = dataStack.pop()
    if first.kind == ntFloat:
      dataStack.push(newFloat(cos(first.fValue)))
    else:
      raise invalidTypeErr($first.kind, "float", "cos")

  of "pow":
    var first = dataStack.pop()
    var second = dataStack.pop()
    if first.kind == ntFloat and second.kind == ntFloat:
      dataStack.push(newFloat(pow(second.fValue, first.fValue)))
    else:
      raise invalidTypeErr($first.kind & " and " & $second.kind, "float and float", "pow")
  of "rand":
    var first = dataStack.pop()
    if first.kind == ntInt:
      randomize()
      dataStack.push(newInt(random(int(first.iValue))))
    else:
      raise invalidTypeErr($first.kind, "int", "rand")
  of "round":
    var first = dataStack.pop()
    if first.kind == ntFloat:
      dataStack.push(newInt(round(first.fValue)))
    else:
      raise invalidTypeErr($first.kind, "float", "round")
  
    # Type conversion
  of "type":
    var first = dataStack.pop()
    dataStack.push(newString($first.kind))
    
  of "int>float":
    var first = dataStack.pop()
    if first.kind == ntInt:
      dataStack.push(newFloat(float(first.iValue)))
    else:
      raise invalidTypeErr($first.kind, "int", "int>float")
      
  of "float>int":
    var first = dataStack.pop()
    if first.kind == ntFloat:
      dataStack.push(newInt(int(first.fValue)))
    else:
      raise invalidTypeErr($first.kind, "float", "float>int")
      
  of "string>int":
    var first = dataStack.pop()
    if first.kind == ntString:
      dataStack.push(newInt(first.value.parseInt()))
    else:
      raise invalidTypeErr($first.kind, "string", "string>int")
  
    # Exception handling
  of "try":
    # (try quot) (excpt quot) try
    var first = dataStack.pop()
    var second = dataStack.pop()
    if first.kind == ntQuot and second.kind == ntQuot:
      try:
        interpretQuotation(second, dataStack, vars, gvars)
      except:
        dataStack.push(newString(getCurrentExceptionMsg()))
        interpretQuotation(first, dataStack, vars, gvars)
    else:
      raise invalidTypeErr($first.kind & " and " & $second.kind, "quot and quot", "try")
  
  of "new":
    var first = dataStack.pop()
    if first.kind == ntVar:
      var tVar: PType
      
      if first.loc == 0:
        tVar = vars.getVar(first.vvalue)
      elif first.loc == 1:
        tVar = gvars.getVar(first.vvalue)
      elif first.loc == 2:
        tVar = vars.getVarField(first.vvalue)
      elif first.loc == 3:
        tVar = gvars.getVarField(first.vvalue)
      else:
        raise newException(ERuntimeError, errorLine() &
            "Error: Variable's location is incorrect, got $1" % [$first.loc])
      
      if tVar == nil:
        raise newException(ERuntimeError, errorLine() &
            "Error: $1 is not declared." % [first.vvalue])
      
      if tVar.kind == ntType:
        var fields: TDict = @[]
        for i in 0 .. len(tVar.fields)-1:
          fields.add((tVar.fields[i], newNil()))
        dataStack.push(newObject(tVar, fields))
  
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
      var s = cmnd.split('.')
      
      # Check if there is a module, with function by the name of whatever s[1] is
      module = getModule(s[0], gvars) # [name, {locals}, {globals}]
      if module == nil:
        tVar = nil
      else:
        tVar = module[2].getVar(s[1])
        varLoc = 1
    
      # FIXME: Perhaps it shouldn't be a dot syntax
      # If i were to use a different method it would simpler i think.
      
      # if the module doesn't exist, then try to see if there is a object, with 
      # a field equal to after
      if module == nil:
        tVar = vars.getVarField(cmnd)
        varLoc = 2 #i.e field, local
        if tVar == nil:
          tVar = gvars.getVarField(cmnd)
          varLoc = 3 #i.e field global
    
    if tVar == nil:
      raise newException(ERuntimeError, errorLine() & "Error: $1 is not declared." % [cmnd])
    
    if tVar.kind != ntFunc:
      dataStack.push(newVar(cmnd, varLoc))
    else:
      callFunc(dataStack, vars, gvars, cmnd, tVar, module)

proc interpretQuotation*(quot: PType, dataStack: var TStack, vars, gvars: var PType) =
  if quot.kind != ntQuot:
    raise newException(EInvalidValue, errorLine() & 
        "Error: Argument given is not a quotation")
  
  for item in items(quot.lvalue):
    case item.kind
    of ntInt, ntFloat, ntString, ntBool, ntList, ntQuot, ntDict, ntNil, ntFunc, ntVar, ntType, ntObject:
      dataStack.push(item)
    of ntCmnd:
      command(item.value, dataStack, vars, gvars)
    of ntAstNode:
      case item.node.kind:
      of nnkVarDeclar:
        if gvars.getVar(item.node.value) != nil:
          raise newException(ERuntimeError, errorLine() &
              "Error: $1 is already declared as a global variable" % [item.node.value])
        else:
          vars.declVar(item.node.value)
      of nnkFunc:
        if gvars.getVarIndex(item.node.fname) == -1:
          gvars.declVar(item.node.fName)
        gvars.setVar(item.node.fName, newFunc(item.node))
      of nnkTuple:
        if gvars.getVarIndex(item.node.tName) == -1:
          gvars.declVar(item.node.tName)
        gvars.setVar(item.node.tName, newType(item.node))  
      
      else:
        raise newException(ERuntimeError, errorLine() & 
            "Error: Unexpected AstNode in quotation, " & $item.node.kind)

proc callFunc*(dataStack: var TStack, vars, gvars: var PType, cmnd: string,
    tVar: PType, module: var seq[PType]) =
  # Function call - Functions don't share scope, but they share the stack.
  
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

  # FIXME: These should REALLY, not be added to global vars. I need to
  # find a solution to the whole args/scope thing. Remember that
  # quotations called in functions need to have the scope of the function.

  var tempArgNames: seq[string] = @[]
  for i in countdown(tVar.args.len()-1, 0):
    var arg = tVar.args[i]
    if arg.kind == ntCmnd:
      #try:
      var first = dataStack.pop()
      # If it's already declared just overwrite it.
      if globalVars.getVar(arg.value) == nil:
        globalVars.declVar(arg.value)
      globalVars.setVar(arg.value, first)
      
      tempArgNames.add(arg.value)
      
      #except EOverflow:
      #  # TODO: Check if this works, After araq fixes the exception bug
      #  raise newException(ERuntimeError, 
      #          "Error: $1 expects $2 args, got $3" %
      #                  [cmnd, $(tVar.args.len()-1), $(i)])

    else:
      raise newException(ERuntimeError, errorLine() & "Error: " & cmnd &
              " contains unexpected args, of kind " & $arg.kind)
              
  
  interpretQuotation(tVar.quot, dataStack, localVars, globalVars)

  # TODO: If a variable with the same name as a arg gets declared in the function
  # An error should be raised.
  # TODO: Check in the function declaration if any of the arguments are already declared as global variables
  
  # Move the variables that were declared global in that function
  # to gvars(or the modules global vars)
  for name, value in items(globalVars.dValue):
    if name notin tempArgNames:
      if module == nil:
        if gvars.getVar(name) == nil:
          gvars.declVar(name)
        gvars.setVar(name, value)
      else:
        if gvars.getVar(name) == nil:
          module[2].declVar(name)
        module[2].setVar(name, value)

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
  var loaded = False
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
            
            # Add the folder where this module resides, to this modules __path__
            if splitFile(module).dir != "":
              var modulePath = globals.getVar("__path__")
              modulePath.lValue.add(newString(path.value / splitFile(module).dir))
              globals.setVar("__path__", modulePath)
              
            var ast = parse(file)
            interpret(ast, moduleStack, locals, globals)
            
            var moduleList = newList(@[newString(extractFilename(module)), locals, globals]) # [name, {locals}, {globals}]
            modulesVar.lValue.add(moduleList)
            loaded = True

        else:
          raise newException(ERuntimeError, errorLine() &
              "Error: Unable to load " & module &
                  ", incorrect path, got type " & $path.kind)

  else:
    raise newException(ERuntimeError, errorLine() & 
        "Error: Unable to load module, path and/or modules variable is not declared.")
        
        
  if not loaded:
    raise newException(ERuntimeError, errorLine() & 
        "Error: Unable to load module(module cannot be found).")
    
proc includeModules(modules: seq[string], dataStack: var TStack, vars, gvars: var PType) =
  var paths = gvars.getVar("__path__")
  var modulesVar = gvars.getVar("__modules__")
  var loaded = False
  if paths != nil and modulesVar != nil:
    for module in items(modules):
      for path in items(paths.lValue):
        if path.kind == ntString:
          var file = readFile(path.value / module & ".nael")
          if file != nil:
            var ast = parse(file)
            
            # Add the folder where this module resides
            if splitFile(module).dir != "":
              paths.lValue.add(newString(path.value / splitFile(module).dir))
              gvars.setVar("__path__", paths)
            
            interpret(ast, dataStack, vars, gvars)
            loaded = True
            break
        else:
          raise newException(ERuntimeError, errorLine() & 
              "Error: Unable to load " & module &
                  ", incorrect path, got type " & $path.kind)

  else:
    raise newException(ERuntimeError, errorLine() & 
        "Error: Unable to load module, path and/or modules variable is not declared.")
  
  if not loaded:
    raise newException(ERuntimeError, errorLine() &
        "Error: Unable to load module(module cannot be found).")


