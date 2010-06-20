# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 13 June 2010

# nimAPI - Allows interfacing between nimrod and nael, and C and nael.
import strutils
type
  # parser.nim
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

  # interpreter.nim
  TDict* = seq[tuple[name: string, value: PType]]

  TTypes* = enum
    ntInt,
    ntFloat,
    ntString,
    ntBool,
    ntList,
    ntQuot,
    ntDict,
    ntNil,
    ntCmnd, # Exclusive to quotations.
    ntVar, # A pointer to a variable
    ntFunc, # Exclusively used only in variables
    ntASTNode, # A PNaelNode - VarDeclar etc, Are declared with this in quotations
    ntType, # Stores type information
    ntObject # Instance of a Type
    
  PType* = ref TType
  TType* = object
    case kind*: TTypes
    of ntInt:
      iValue*: int64
    of ntFloat:
      fValue*: float64
    of ntString, ntCmnd:
      value*: string # for ntCmnd, name of cmnd.
    of ntBool:
      bValue*: bool
    of ntList, ntQuot:
      lValue*: seq[PType]
    of ntDict:
      dValue*: TDict
    of ntNil: nil
    of ntFunc:
      args*: seq[PType]
      quot*: PType
    of ntASTNode:
      node*: PNaelNode
    of ntVar:
      vvalue*: string
      loc*: int # 0 for local, 1 for global, 2 for localfield, 3 for globalfield
      val*: PType
    of ntType:
      name*: string
      specialType*: string # A special type, indicates one of the built-in types, e.g string, int
      fields*: seq[string]
    of ntObject:
      typ*: PType # the ntType
      oFields*: TDict
      
  TStack* = tuple[stack: seq[PType], limit: int]
  
  ERuntimeError* = object of EBase

proc `$`*(kind: TTypes): string =
  case kind
  of ntInt: return "int"
  of ntFloat: return "float"
  of ntString: return "string"
  of ntBool: return "bool"
  of ntList: return "list"
  of ntQuot: return "quot"
  of ntDict: return "dict"
  of ntNil: return "nil"
  of ntCmnd: return "__cmnd__"
  of ntVar: return "var"
  of ntFunc: return "__func__"
  of ntASTNode: return "__ASTNode__"
  of ntType: return "type"
  of ntObject: return "object"

proc invalidTypeErr*(got, expected, function: string): ref ERuntimeError =
  return newException(ERuntimeError, "Error: Invalid types, $1 expects $2, got $3" % [function, expected, got])