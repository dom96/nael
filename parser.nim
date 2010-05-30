# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 29 May 2010

# Syntactic analyser - Calls the lexer and turns it's output into an AST
import lexer, strutils

type

  PNaelNodeKind* = ref TNaelNodeKind  
  
  TNaelNodeKind* = enum
    nnkNil, # nil
    nnkCommand, # This might be a var, or a function like `print`
    nnkStringLit, # "string"
    nnkIntLit, # 1
    nnkFloatLit, # 1.0
    nnkListLit, # [5]
    nnkQuotLit, # ("some code here" print)
    nnkVarDeclar, # x let
    nnkVarSet, # x 5 =
    nnkFunc # func [args] (...);
    
  PNaelNode* = ref TNaelNode
    
  TNaelNode* = object
    case kind*: TNaelNodeKind
    of nnkListLit, nnkQuotLit:
      children*: seq[PNaelNode]
    of nnkCommand, nnkStringLit, nnkVarDeclar:
      value*: string
    of nnkVarSet:
      name*: string
      setValue*: PNaelNode
    of nnkFunc:
      fName*: string
      args*: PNaelNode # List
      quot*: PNaelNode # Quotation
    of nnkIntLit:
      iValue*: int
    of nnkFloatLit:
      fValue*: float
    of nnkNil:
      nil
      
  ESyntaxError = object of EBase

proc getChar(tokens: seq[string], i: int): int =
  result = 0
  for t in 0 .. len(tokens)-1:
    inc(result, tokens[t].len())

proc tokenIsNumber(token: string): bool =
  for i in items(token):
    if i in {'0'..'9'}:
      result = True
    else:
      return False

proc tokenIsFloat(token: string): bool =
  var dot = False
  var nr = False
  for i in items(token):
    if i in {'0'..'9'}:
      nr = True
    elif i == '.':
      dot = True
    else:
      return False
  
  if dot and nr:
    return True

proc parse*(code: string): seq[PNaelNode] =
  # Parse code into an AST
  result = @[]
  
  var lines = splitLines(code)
  for codeLine in 0 .. len(lines)-1:
    var tokens = analyse(lines[codeLine])    
    
    var i  = 0
    while True:
      if tokens.len()-1 < i:
        break
        
      case tokens[i]
      of "(":
        # Everything in between ( and ) is one token.
        if tokens.len()-i > 2 and tokens[i + 2] == ")":
          var quotNode: PNaelNode
          new(quotNode)
          quotNode.kind = nnkQuotLit
          quotNode.children = parse(tokens[i + 1])
          
          # Skip the quotation and ')'
          inc(i, 2)
          
          result.add(quotNode)
        else:
          raise newException(ESyntaxError, 
              "[Line: $1, Char: $2] SyntaxError: Quotation not ended" %
                  [$codeLine, $getChar(tokens, i)])
      
      of "[":

        # Everything in between [ and ] is one token.
        if tokens.len()-i > 2 and tokens[i + 2] == "]":
          var listNode: PNaelNode
          new(listNode)
          listNode.kind = nnkListLit
          listNode.children = parse(tokens[i + 1])
        
          # skip the list and ']'
          inc(i, 2)
      
          result.add(listNode)
        else:
          raise newException(ESyntaxError, 
              "[Line: $1, Char: $2] SyntaxError: List not ended" %
                  [$codeLine, $getChar(tokens, i)])
      
      else:
        if tokenIsNumber(tokens[i]):
          var intNode: PNaelNode
          new(intNode)
          intNode.kind = nnkIntLit
          intNode.iValue = tokens[i].parseInt()
          result.add(intNode)
        
        elif tokenIsFloat(tokens[i]):
          var floatNode: PNaelNode
          new(floatNode)
          floatNode.kind = nnkFloatLit
          floatNode.fValue = tokens[i].parseFloat()
          result.add(floatNode)
        
        elif tokens[i].startswith("\""):
          var strNode: PNaelNode
          new(strNode)
          strNode.kind = nnkStringLit
          # Get rid of the " 
          var val = tokens[i].copy(1, tokens[i].len()-1)
          val = val.copy(0, val.len()-2)
          strNode.value = val
          result.add(strNode)
        
        else:
          # Test for special expressions here.
          
        
          if tokens.len()-i > 1 and tokens[i + 1] == "let":
            # x let -> VarDeclaration(x)
            var declNode: PNaelNode
            new(declNode)
            declNode.kind = nnkVarDeclar
            declNode.value = tokens[i]
            
            # Move from x to let, then the inc(i) at the bottom will move
            # to the token after 'let'
            inc(i)
        
            result.add(declNode)
          elif tokens.len()-i > 2 and tokens[i + 2] == "=":
            # x 5 =
            var setNode: PNaelNode
            new(setNode)
            setNode.kind = nnkVarSet
            setNode.name = tokens[i]
            setNode.setValue = parse(tokens[i + 1])[0]
            
            # Move from x to =, then the inc(i) at the bottom will move
            # to the token after '='
            inc(i, 2)
        
            result.add(setNode)
        
          elif tokens.len()-i > 2 and tokens[i + 3] == ";":
            # foo [args] (...);
            var funcNode: PNaelNode
            new(funcNode)
            funcNode.kind = nnkFunc
            funcNode.fName = tokens[i]
            funcNode.args = parse(tokens[i + 1])[0]
            funcNode.quot = parse(tokens[i + 2])[0]
            
            inc(i, 3)
            
            result.add(funcNode)
        
          else:
            var cmndNode: PNaelNode
            new(cmndNode)
            cmndNode.kind = nnkCommand
            cmndNode.value = tokens[i]
            result.add(cmndNode)
        
      inc(i)
        
proc `$`(ast: seq[PNaelNode]): string =
  result = ""
  for n in items(ast):
    case n.kind
    of nnkQuotLit:
      result.add("QuotSTART\n" & $n.children & "QuotEND\n")
    of nnkListLit:
      result.add("ListSTART\n" & $n.children & "ListEND\n")
    of nnkCommand:
      result.add("CMND(" & n.value & ")\n")
    of nnkVarDeclar:
      result.add("VarDeclaration(" & n.value & ")\n")
    of nnkVarSet:
      var setValue = $(@[n.setValue])
      result.add("VarSET($1, $2)\n" % [n.name, setValue.replace("\n", "")])
    of nnkFunc:
      var args = $(@[n.args])
      args = args.replace("\n", "")
      var quot = $(@[n.quot])
      quot = quot.replace("\n", "")
    
      result.add("Func($1, $2, $3)\n" % [n.fName, args, quot])
    of nnkStringLit:
      result.add("STR(\"" & n.value & "\")\n")
    of nnkIntLit:
      result.add("INT(" & $n.iValue & ")\n")
    of nnkFloatLit:
      result.add("FLOAT(" & $n.fValue & ")\n")
    of nnkNil:
      result.add("nil\n")
      
      
when isMainModule:
  #echo(parse("(\"5\" 10)").len())
  echo(parse("func [arg] (10 print); "))
      
      