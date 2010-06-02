# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 29 May 2010

# Lexical analyser

proc analyse*(code: string): seq[string] =
  result = @[]

  var r = ""

  var i = 0
  while True:
    case code[i]
    of '\0':
      if r != "":
        result.add(r)
      break
    of ' ', ',', '\L', '\c': # Chars to ignore, these also mark the end of a token
      if r != "":
        result.add(r)
        r = ""
    
    of '[', '(':
      # Add any token which is left.
      if r != "":
        result.add(r)
        r = ""
      
      # Add [ or ( as a seperate token.
      result.add($code[i])
      
      inc(i) # Skip the [ or (
      var opMet = 1 # The number of times [ or ( was matched.
                    # This gets decreased when ] or ) is met.
      while True:
        case code[i]
        of '\0':
          if r != "":
            result.add(r)
          return
        of '[', '(':
          inc(opMet)
          r.add($code[i])
        of ']', ')':
          if opMet == 1:
            # Add everything between ( and ) or [ and ]
            result.add(r)
            r = ""
            
            # Add ) or ]
            result.add($code[i])
            break
          else:
            dec(opMet)
            r.add($code[i])
            
        else:
          r = r & code[i]
        inc(i)

    
    of '\"':
      # Add any token which is waiting to get added
      if r != "":
        result.add(r)
        r = ""
      
      # Add " as a seperate token
      result.add($code[i])
      
      # skip the "
      inc(i)
      
      while True:
        case code[i]
        of '\0':
          if r != "":
            result.add(r)
          return
        of '"':
          result.add(r)
          r = ""
          
          result.add($code[i])
          break
        else:
          r.add($code[i])
        
        inc(i)
    
    else:
      r = r & code[i]
      
    inc(i)
      
when isMainModule:
  for i in items(analyse("x let, x 5 = x print")):
    if i != "":
      echo(i)
    else:
      echo("<>EMPTY<>")