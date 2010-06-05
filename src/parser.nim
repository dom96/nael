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
    nnkFunc # func [args] (...);
    
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
    of nnkIntLit:
      iValue*: int64
    of nnkFloatLit:
      fValue*: float64

var lineCount: int = 0
var charCount: int = 0

proc getChar(tokens: seq[string], i: int): int =
  result = 0
  for t in 0 .. len(tokens)-1:
    inc(result, tokens[t].len())

proc tokenIsNumber(token: string): bool =
  if token == "-":
    return False

  for i in items(token):
    if i in {'0'..'9'}:
      result = True
    elif i == '-':
      result = False
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
    elif i == '-':
      nil
    else:
      return False
  
  if dot and nr:
    return True

proc parse*(code: string): seq[PNaelNode] =
  # Parse code into an AST
  result = @[]
  
  # Reset the values
  lineCount = 0
  charCount = 0
  
  var tokens = analyse(code)    
  
  var i = 0
  while True:
    if tokens.len()-1 < i:
      break
    
    case tokens[i]
    of "(":
      # Everything in between ( and ) is one token.
      if tokens.len()-i > 2 and tokens[i + 2] == ")":
        var quotNode: PNaelNode
        new(quotNode)
        quotNode.lineNum = lineCount
        quotNode.charNum = charCount
        quotNode.kind = nnkQuotLit
        quotNode.children = parse(tokens[i + 1])
        
        # Skip the quotation and ')'
        inc(i, 2)
        
        result.add(quotNode)
      else:
        raise newException(ESystem, 
            "[$1, $2] SyntaxError: Quotation not ended" %
                [$lineCount, $charCount])
    
    of "[":
      # Everything in between [ and ] is one token.
      if tokens.len()-i > 2 and tokens[i + 2] == "]":
        var listNode: PNaelNode
        new(listNode)
        listNode.lineNum = lineCount
        listNode.charNum = charCount
        listNode.kind = nnkListLit
        listNode.children = parse(tokens[i + 1])
      
        # skip the list and ']'
        inc(i, 2)
    
        result.add(listNode)
      else:
        raise newException(ESystem, 
            "[$1, $2] SyntaxError: List not ended" %
                [$lineCount, $charCount])
    
    of "\"":
      # Everything in between " and " is one token.
      if tokens.len()-i > 2 and tokens[i + 2] == "\"":
        var strNode: PNaelNode
        new(strNode)
        strNode.lineNum = lineCount
        strNode.charNum = charCount
        strNode.kind = nnkStringLit
        strNode.value = tokens[i + 1]
        
        # skip the string and "
        inc(i, 2)
        
        result.add(strNode)
      else:
        raise newException(ESystem, 
            "[$1, $2] SyntaxError: String not ended" %
                [$lineCount, $charCount])
    
      # Line/Char guidelines ONLY
    of "\\n":
      inc(lineCount)
      charCount = 0
    
    of ",", " ":
      # Don't increase here, it gets increased before 'inc(i)' is called.
      # Ignore these...
      nil
    
    else:
      if tokenIsNumber(tokens[i]):
        var intNode: PNaelNode
        new(intNode)
        intNode.lineNum = lineCount
        intNode.charNum = charCount
        intNode.kind = nnkIntLit
        intNode.iValue = tokens[i].parseInt()
        result.add(intNode)
      
      elif tokenIsFloat(tokens[i]):
        var floatNode: PNaelNode
        new(floatNode)
        floatNode.lineNum = lineCount
        floatNode.charNum = charCount
        floatNode.kind = nnkFloatLit
        floatNode.fValue = tokens[i].parseFloat()
        result.add(floatNode)
      
      else:
        # Test for special expressions here.
        
        if tokens.len()-i > 1 and tokens[i + 1] == "let":
          # x let -> VarDeclaration(x)
          var declNode: PNaelNode
          new(declNode)
          declNode.lineNum = lineCount
          declNode.charNum = charCount
          declNode.kind = nnkVarDeclar
          declNode.value = tokens[i]
          
          # Move from x to let, then the inc(i) at the bottom will move
          # to the token after 'let'
          inc(i)
      
          result.add(declNode)
          
        elif tokens.len()-i > 7 and tokens[i + 7] == ";":
          # each [ is one token, same goes for (, ] and ]
          # foo [args] (...);
          var funcNode: PNaelNode
          new(funcNode)
          funcNode.lineNum = lineCount
          funcNode.charNum = charCount
          funcNode.kind = nnkFunc
          funcNode.fName = tokens[i]
          funcNode.args = parse(tokens[i + 1] & tokens[i + 2] & tokens[i + 3])[0]
          funcNode.quot = parse(tokens[i + 4] & tokens[i + 5] & tokens[i + 6])[0]
          
          inc(i, 7)
          
          result.add(funcNode)
      
          # TODO: Tuples
      
        else:
          
          var cmndNode: PNaelNode
          new(cmndNode)
          cmndNode.lineNum = lineCount
          cmndNode.charNum = charCount
          cmndNode.kind = nnkCommand
          cmndNode.value = tokens[i]
          result.add(cmndNode)
      
    # Increase the char count, by the length of the token.
    inc(charCount, tokens[i].len())
    
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

proc `$`(ast: seq[PNaelNode]): string =
  result = ""
  for n in items(ast):
    result.add($n & "\n")

when isMainModule:
  echo parse("-5\n \n 56 - (-56.7")

  discard """

  var t = times.getStartMilsecs()
  var ti = times.getTime()

  echo parse("x [[90], 6] =")

  var t1 = times.getStartMilsecs()
  var ti1 = times.getTime()
  echo("Time taken = ", t1 - t, "ms")
  echo("Other Time taken = ", int(ti1) - int(ti), "s")"""
      
      