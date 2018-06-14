# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 29 May 2010

# Lexical analyser

type
  TTokens = tuple[token: string, curLine, curChar: int]


proc analyse*(code: string): seq[TTokens] =
  var currentLine = 0
  var currentChar = 0


  result = @[]

  var r = ""

  var i = 0
  while true:
    if code.len == i:
      if r != "":
        result.add((r, currentLine, currentChar))
      break
    
    case code[i]
    of ' ', ',', '\L', '\c': # Chars to ignore, these also mark the end of a token
      if r != "":
        result.add((r, currentLine, currentChar))
        r = ""
    
      if code[i] == '\L' or code[i] == '\c':
        inc(currentLine)
        currentChar = 0
    
    of '[', '(':
      # Add any token which is left.
      if r != "":
        result.add((r, currentLine, currentChar))
        r = ""
      
      # Add [ or ( as a seperate token.
      result.add(($code[i], currentLine, currentChar))
      
      inc(currentChar) # When increasing i, currentChar needs to be increased aswell
      inc(i) # Skip the [ or (
      
      var opMet = 1 # The number of times [ or ( was matched.
                    # This gets decreased when ] or ) is met.
      while true:
        if code.len == i:
          if r != "":
            result.add((r, currentLine, currentChar))
          return
        
        case code[i]
        of '[', '(':
          inc(opMet)
          r.add($code[i])
        of ']', ')':
          if opMet == 1:
            # Add everything between ( and ) or [ and ]
            result.add((r, currentLine, currentChar))
            r = ""
            
            # Add ) or ]
            result.add(($code[i], currentLine, currentChar))
            break
          else:
            dec(opMet)
            r.add($code[i])
        
        of '\"':
          # Add the " first
          r.add($code[i])
          inc(currentChar) # When increasing i, currentChar needs to be increased aswell
          inc(i) # Then Skip the starting "
          while true:
            if code[i] == '\"':
              r.add($code[i])
              break
            else:
              r.add($code[i])
            inc(currentChar) # When increasing i, currentChar needs to be increased aswell
            inc(i)
        
        else:
          r = r & code[i]
        inc(currentChar) # When increasing i, currentChar needs to be increased aswell
        inc(i)

    
    of ')', ']':
      # Add these as seperate tokens
      if r != "":
        result.add((r, currentLine, currentChar))
        r = ""
    
      result.add(($code[i], currentLine, currentChar))
    
    of '\"':
      # Add any token which is waiting to get added
      if r != "":
        result.add((r, currentLine, currentChar))
        r = ""
      
      # Add " as a seperate token
      result.add(($code[i], currentLine, currentChar))
      
      # skip the "
      inc(currentChar) # When increasing i, currentChar needs to be increased aswell
      inc(i)
      
      while true:
        if code.len == i:
          if r != "":
            result.add((r, currentLine, currentChar))
          return
        
        case code[i]
        of '\"':
          result.add((r, currentLine, currentChar))
          r = ""
          
          result.add(($code[i], currentLine, currentChar))
          break
        else:
          r.add($code[i])
        
        inc(currentChar) # When increasing i, currentChar needs to be increased aswell
        inc(i)
    
    of '#':
      # Add any token which is waiting to get added
      if r != "":
        result.add((r, currentLine, currentChar))
        r = ""
        
      while true:
        if code.len == i:
          return
        case code[i]
        of '\L', '\c':
          inc(currentLine)
          currentChar = 0
          break
        else:
          discard
        inc(currentChar) # When increasing i, currentChar needs to be increased aswell
        inc(i)
    
    else:
      r = r & code[i]
    
    inc(currentChar)
    inc(i)
      
when isMainModule:
  for i, cL, cC in items(analyse("func foo [arg] (((\"test\" print) call) call);")):
    if i != "":
      echo(i)
    else:
      echo("<>EMPTY<>")
