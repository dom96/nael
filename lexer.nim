# Copyright 2010 (C) Dominik Picheta - Read license.txt for the license.
# 29 May 2010

# Lexical analyser

proc analyse*(code: string): seq[string] =
  result = @[]
  var stringStarted = False

  var r = ""

  var i = 0
  while True:
    case code[i]
    of '\0':
      result.add(r)
      break
    of ' ', ',':
      if not stringStarted:
        if r != "":
          result.add(r)
          r = ""
      else:
        r = r & code[i]
    
    of '[', '(':
      if not stringStarted:
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

      else:
        r = r & code[i]
    
    of '"':
      r = r & code[i]
      stringStarted = not stringStarted
    
    else:
      r = r & code[i]
    inc(i)
      
when isMainModule:
  for i in items(analyse("\"5\" 10 print")):
    echo(i)