# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 29 May 2010

# Syntactic analyser - Calls the lexer and turns it's output into an AST
import lexer, strutils

type
  PNaelNodeKind* = ref TNaelNodeKind  
  
  TNaelNodeKind* = enum
    nnkCommand, # This might be a var, or a function like `print`
    nnkStringLit, # "string"
    nnkIntLit, # 1
    nnkFloatLit, # 1.0
    nnkListLit, # [5]
    nnkQuotLit, # ("some code here" print)
    nnkVarDeclar, # x let
    nnkFunc, # func foo [args] (...);
    nnkTuple # name [ fields ] tuple
    
  PNaelNode* = ref TNaelNode
    
  TNaelNode* = object
    lineNum*: int
    charNum*: int
    case kind*: TNaelNodeKind
    of nnkListLit, nnkQuotLit:
      children*: seq[PNaelNode]
    of nnkCommand, nnkStringLit, nnkVarDeclar:
      value*: string
    of nnkFunc:
      fName*: string
      args*: PNaelNode # List
      quot*: PNaelNode # Quotation
    of nnkTuple:
      tName*: string
      fields*: PNaelNode # List
    of nnkIntLit:
      iValue*: int64
    of nnkFloatLit:
      fValue*: float64

proc getChar(tokens: seq[string], i: int): int =
  result = 0
  for t in 0 .. len(tokens)-1:
    inc(result, tokens[t].len())

proc tokenIsNumber(token: string): bool =
  if token == "-":
    return false

  for i in items(token):
    if i in {'0'..'9'}:
      result = true
    elif i == '-':
      result = false
    else:
      return false

proc tokenIsFloat(token: string): bool =
  var dot = false
  var nr = false
  for i in items(token):
    if i in {'0'..'9'}:
      nr = true
    elif i == '.':
      dot = true
    elif i == '-':
      discard
    else:
      return false
  
  if dot and nr:
    return true

proc parse*(code: string): seq[PNaelNode] =
  # Parse code into an AST
  result = @[]
  
  var tokens = analyse(code) # (token, lineNum, charNum)
  
  var i = 0
  while true:
    if tokens.len()-1 < i:
      break
    
    case tokens[i][0]
    of "(":
      # Everything in between ( and ) is one token.
      # If an empty quot is present, (), then the token between is an empty string ""
      if tokens.len()-i > 2 and tokens[i + 2][0] == ")":
        var quotNode: PNaelNode
        new(quotNode)
        quotNode.lineNum = tokens[i][1]
        quotNode.charNum = tokens[i][2]
        quotNode.kind = nnkQuotLit
        quotNode.children = parse(tokens[i + 1][0])
        
        # Skip the quotation and ')'
        inc(i, 2)
        
        result.add(quotNode)
      else:
        raise newException(SystemError, 
            "[Line: $1 Char: $2] SyntaxError: Quotation not ended" %
                [$tokens[i][1], $tokens[i][2]])
    
    of "[":
      # Everything in between [ and ] is one token.
      # If an empty list is present, [], then the token between is an empty string ""
      if tokens.len()-i > 2 and tokens[i + 2][0] == "]":
        var listNode: PNaelNode
        new(listNode)
        listNode.lineNum = tokens[i][1]
        listNode.charNum = tokens[i][2]
        listNode.kind = nnkListLit
        listNode.children = parse(tokens[i + 1][0])
      
        # skip the list and ']'
        inc(i, 2)
    
        result.add(listNode)
      else:
        raise newException(SystemError, 
            "[Line: $1 Char: $2] SyntaxError: List not ended" %
                [$tokens[i][1], $tokens[i][2]])
    
    of "]", ")":
      if tokens[i][0] == "]":
        raise newException(SystemError, 
                    "[Line: $1 Char: $2] SyntaxError: List not started" %
                        [$tokens[i][1], $tokens[i][2]])
      elif tokens[i][0] == ")":
        raise newException(SystemError, 
                    "[Line: $1 Char: $2] SyntaxError: Quotation not started" %
                        [$tokens[i][1], $tokens[i][2]])
    
    of "\"":
      # Everything in between " and " is one token.
      if tokens.len()-i > 2 and tokens[i + 2][0] == "\"":
        var strNode: PNaelNode
        new(strNode)
        strNode.lineNum = tokens[i][1]
        strNode.charNum = tokens[i][2]
        strNode.kind = nnkStringLit
        strNode.value = tokens[i + 1][0]
        
        # skip the string and "
        inc(i, 2)
        
        result.add(strNode)
      else:
        raise newException(SystemError, 
            "[Line: $1 Char: $2] SyntaxError: String not ended" %
                [$tokens[i][1], $tokens[i][2]])
    
    of "func":
        if tokens.len()-i > 8 and tokens[i + 8][0] == ";":
          # each [ is one token, same goes for (, ] and ]
          # func foo [args] (...);
          var funcNode: PNaelNode
          new(funcNode)
          funcNode.lineNum = tokens[i][1]
          funcNode.charNum = tokens[i][2]
          funcNode.kind = nnkFunc
          funcNode.fName = tokens[i + 1][0]
          funcNode.args = parse(tokens[i + 2][0] & tokens[i + 3][0] & tokens[i + 4][0])[0]
          funcNode.quot = parse(tokens[i + 5][0] & tokens[i + 6][0] & tokens[i + 7][0])[0]
          
          inc(i, 8)
          
          result.add(funcNode)
        else:
          raise newException(SystemError, 
              "[Line: $1 Char: $2] SyntaxError: Invalid function declaration" %
                  [$tokens[i][1], $tokens[i][2]])
    
    else:
      if tokenIsNumber(tokens[i][0]):
        var intNode: PNaelNode
        new(intNode)
        intNode.lineNum = tokens[i][1]
        intNode.charNum = tokens[i][2]
        intNode.kind = nnkIntLit
        intNode.iValue = tokens[i][0].parseInt()
        result.add(intNode)
      
      elif tokenIsFloat(tokens[i][0]):
        var floatNode: PNaelNode
        new(floatNode)
        floatNode.lineNum = tokens[i][1]
        floatNode.charNum = tokens[i][2]
        floatNode.kind = nnkFloatLit
        floatNode.fValue = tokens[i][0].parseFloat()
        result.add(floatNode)
      
      else:
        # Test for special expressions here.
        
        if tokens.len()-i > 1 and tokens[i + 1][0] == "let":
          # x let -> VarDeclaration(x)
          var declNode: PNaelNode
          new(declNode)
          declNode.lineNum = tokens[i][1]
          declNode.charNum = tokens[i][2]
          declNode.kind = nnkVarDeclar
          declNode.value = tokens[i][0]
          
          # Move from x to let, then the inc(i) at the bottom will move
          # to the token after 'let'
          inc(i)
      
          result.add(declNode)
      
        elif tokens.len()-i > 4 and tokens[i + 4][0] == "tuple":
          # each [ is one token
          # name [ field1 field2 ] tuple
          var tupleNode: PNaelNode
          new(tupleNode)
          tupleNode.lineNum = tokens[i][1]
          tupleNode.charNum = tokens[i][2]
          tupleNode.kind = nnkTuple
          tupleNode.tName = tokens[i][0]
          tupleNode.fields = parse(tokens[i + 1][0] & tokens[i + 2][0] & tokens[i + 3][0])[0]
      
          inc(i, 4)
          
          result.add(tupleNode)
      
        else:
          
          var cmndNode: PNaelNode
          new(cmndNode)
          cmndNode.lineNum = tokens[i][1]
          cmndNode.charNum = tokens[i][2]
          cmndNode.kind = nnkCommand
          cmndNode.value = tokens[i][0]
          result.add(cmndNode)
    
    inc(i)

# for Debugging ONLY
proc `$`*(n: PNaelNode): string =
  result = ""
  case n.kind
  of nnkQuotLit:
    result.add("QuotSTART")
    for i in items(n.children):
      result.add(" " & $i & " ")
    result.add("QuotEND")
    
  of nnkListLit:
    result.add("ListSTART")
    for i in items(n.children):
      result.add(" " & $i & " ")
    result.add("ListEND")
  of nnkCommand:
    result.add("CMND(" & n.value & ")")
  of nnkVarDeclar:
    result.add("VarDeclaration(" & n.value & ")")
  of nnkFunc:
    var args = $(n.args)
    var quot = $(n.quot)
  
    result.add("Func($1, $2, $3)" % [n.fName, args, quot])
  of nnkStringLit:
    result.add("STR(\"" & n.value & "\")")
  of nnkIntLit:
    result.add("INT(" & $n.iValue & ")")
  of nnkFloatLit:
    result.add("FLOAT(" & $n.fValue & ")")
  of nnkTuple:
    result.add("tuple($1, $2)" % [n.tName, $(n.fields)])

proc `$`(ast: seq[PNaelNode]): string =
  result = ""
  for n in items(ast):
    result.add($n & "\n")

when isMainModule:
  echo parse("func foo [arg] (print);")

  discard """

  var t = times.getStartMilsecs()
  var ti = times.getTime()

  echo parse("x [[90], 6] =")

  var t1 = times.getStartMilsecs()
  var ti1 = times.getTime()
  echo("Time taken = ", t1 - t, "ms")
  echo("Other Time taken = ", int(ti1) - int(ti), "s")"""
      
      