# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 29 May 2010

# Syntactic analyser - Calls the lexer and turns it's output into an AST
import lexer, strutils

type

  PNaelNodeKind* = ref TNaelNodeKind  
  
  TNaelNodeKind* = enum
    nnkNil, # nil
    nnkCommand, # `var` or `print` or `call`
    nnkStringLit, # "string"
    nnkIntLit, # 1
    nnkFloatLit, # 1.0
    nnkListLit, # [5]
    nnkQuotLit # ("some code here" print)
    
    
  PNaelNode* = ref TNaelNode
    
  TNaelNode* = object
    case kind*: TNaelNodeKind
    of nnkListLit, nnkQuotLit:
      children*: seq[PNaelNode]
    of nnkCommand, nnkStringLit:
      value*: string
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

proc parse*(code: string): seq[PNaelNode] =
  result = @[]
  
  var lines = splitLines(code)
  for codeLine in 0 .. len(lines)-1:
    var tokens = analyse(lines[codeLine])    
    
    for i in 0 .. len(tokens)-1:
      case tokens[i]
      of "(":
        var quotNode: PNaelNode
        new(quotNode)
        quotNode.kind = nnkQuotLit
        quotNode.children = parse(tokens[i + 1])
        
        if tokens.len() > 2 and tokens[i + 2] == ")":
          result.add(quotNode)
        else:
          raise newException(ESyntaxError, 
              "[Line: $1, Char: $2] SyntaxError: Quotation not ended" %
                  [$codeLine, $getChar(tokens, i)])
                  
      else:
        if tokenIsNumber(tokens[i]):
          var intNode: PNaelNode
          new(intNode)
          intNode.kind = nnkIntLit
          intNode.iValue = tokens[i].parseInt()
          result.add(intNode)
        
proc `$`(ast: seq[PNaelNode]): string =
  result = ""
  for n in items(ast):
    case n.kind
    of nnkListLit, nnkQuotLit:
      result.add("QuotSTART\n" & $n.children & "QuotEND\n")
    of nnkCommand:
      result.add("CMND(" & n.value & ")")
    of nnkStringLit:
      result.add("STR(\"" & n.value & "\")")
    of nnkIntLit:
      result.add("INT(" & $n.iValue & ")\n")
    of nnkFloatLit:
      result.add($n.fValue)
    of nnkNil:
      result.add("nil")
      
      
when isMainModule:
  #echo(parse("(5)").len())
  echo(parse("(5 10)"))
      
      