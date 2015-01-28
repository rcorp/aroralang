{
  var stack = [];
  var variables = {};
  function pushResult (result) {
    stack.push(result);
    return result;
  }
}
start 
  = expr* {return ( JSON.stringify(variables))}


//All the prebuilt Operators
operator

  //No operand
  = "Digit"        {return "\d"}
  / "Not Digit"    {return "\D"}
  / "Word"         {return "\w"}
  / "Not Word"     {return "\W"}
  / "Space"        {return "\s"}
  / "Not Space"    {return "\S"}
  / "Tab"          {return "\t"}
  / "Return"       {return "\r"}
  / "Linefeed"     {return "\n"}
  / "Vertical Tab" {return "\v"}
  / "Form Feed"    {return "\f"}
  / "Backspace"    {return "\b"}
  / "Null"         {return "\0"}

  //Single Operand
  / "Control"      lparen ex:expr2    rparen {return ('(?:\c' + ex + ')')}
  / "Code"         lparen ex:expr2    rparen {return ('(?:' + ex + ')')}
  / "Begins With"  lparen ex:expr2    rparen {return ('(?:^' + ex + ')')}
  / "Ends With"    lparen ex:expr2    rparen {return ('(?:' + ex + '$)')}
  / "Zero Or More" lparen ex:expr2    rparen {return ('(?:' + ex + ')*')}
  / "Zero Or One"  lparen ex:expr2    rparen {return ('(?:' + ex + '?)')}  
  / "One Or More"  lparen ex:expr2    rparen {return ('(?:' + ex + ')+')}
  / "Any Of"       lparen ex:expr2    rparen {return ('[(?:' + ex + ')]')}
  / "None Of"      lparen ex:expr2    rparen {return ('[^(?:' + ex + ')]')}
  / "Ends With"    lparen ex:expr2    rparen {return ('(?:' + ex + '$)')}
  / "Match"        lparen ex:expr2    rparen {return ('(?:' + ex + ')')}
  //Special Case of Match
  / ws             st:string          ws     {return (st)}
  
  
  //Double Operand
  / lparen ex1:expr2 ws rparen ws "Or"              lparen ex2:expr2 rparen {return ('(?:' + ex1 + '|' + ex2 + ')')}
  / lparen ex1:expr2 ws rparen ws "Followed By"     lparen ex2:expr2 rparen {return ('(?:' + ex1 + '(?=' + ex2 + '))')}
  / lparen ex1:expr2 ws rparen ws "Not Followed By" lparen ex2:expr2 rparen {return ('(?:' + ex1 + '(?!' + ex2 + '))')}
  / lparen ex1:expr2 ws rparen ws "To"              lparen ex2:expr2 rparen {return (ex1 + '-' +ex2)} 
  /               lparen in1:integer rparen "Times" lparen ex:expr2 rparen {return ('(?:' + ex + '{' +  in1 +'})')}
  / "At Least"    lparen in1:integer rparen "Times" lparen ex:expr2 rparen {return ('(?:' + ex + '{' +  in1 +',})')}  
  
  
  //Ternary Operand
  / lparen in1:integer rparen "To" lparen in2:integer rparen "Times" lparen ex:expr2 rparen {return ('(?:' + ex + '{' +  in1 +',' + in2 + '})')}


expr 
 = op:operator comma      ex:expr {return pushResult (op) + ex}
 
 //For terminating statements with a ;
 / op:operator terminator         {pushResult(op); var r = stack.reverse().join(''); stack = []; return r}
 
 //So we don't have to put a ; at the end of the last expr or inside an operator
 // op:operator ws         !expr   {return pushResult(op)}
 
 //User defined operator definition 
 / uop:useroperator equals     ex:expr2 {variables[uop] = ex}
 / uop:useroperator comma      ex:expr2 {if (variables[uop]) {return pushResult(variables[uop]) + expr2}}

//We need these expressions inside operators, though rules are the same.
//We simply return the result and don't push them to our stack.
expr2 
 = op:operator      comma      ex:expr2 {return (op + ex);}
 / op:operator      terminator          {return (op)}
 / op:operator      ws                  {return op}
 / uop:useroperator terminator          {return variables[uop] }
 / uop:useroperator comma ex:expr2      {return (variables[uop] + ex) }
 

 
lparen
  = ws "(" ws
  
rparen
  = ws ")" ws
  
comma
  = ws "," ws

terminator
  = ws ";" ws
  
equals
 = ws "=" ws

useroperator
 = name: [a-z]* {return name.join("")}

integer "integer"
  = digits:[0-9]+ { return parseInt(digits.join(""), 10); }
  
string "string"
  = double_quote chars:char* double_quote { return chars.join("").replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"); }

ws "whitespace" = [ \t\n\r]*

char
  = unescaped
  / escape
    sequence:(
        '"'
      / "\\"
      / "/"
      / "b" { return "\b"; }
      / "f" { return "\f"; }
      / "n" { return "\n"; }
      / "r" { return "\r"; }
      / "t" { return "\t"; }
      / "u" digits:$(HEXDIG HEXDIG HEXDIG HEXDIG) {
          return String.fromCharCode(parseInt(digits, 16));
        }
    )
    { return sequence; }

escape         = "\\"
double_quote   = '"'
single_quote   = "'"
               
unescaped      = [\x20-\x21\x23-\x5B\x5D-\u10FFFF]

/* ----- Core ABNF Rules ----- */

/* See RFC 4234, Appendix B (http://tools.ietf.org/html/rfc4627). */
DIGIT  = [0-9]
HEXDIG = [0-9a-f]i