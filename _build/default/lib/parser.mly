%{
    open Ast
%}


%token LParen
%token RParen
%token Equal
%token Colon
%token Arrow
%token DoubleArrow
%token <string> Id
%token <string> String
%token <int> Int
%token TBool
%token TInt
%token TUnit
%token TString
%token True
%token False
%token Let
%token Rec
%token Type
%token In
%token Pipe
%token Plus
%token Minus
%token Times
%token Divide
%token Mod
%token Less
%token Concat
%token Of
%token And
%token Or
%token Not
%token Negate
%token DoubleSemicolon
%token If
%token Then
%token Else
%token Fun
%token Match
%token With
%token Comma

%token EOF


%left Or
%left And
%left Less
%left Equal
%left Concat
%left Minus
%left Plus
%left Arrow
%left Mod
%left Divide
%left Times
(*
%left Negate
%left Not
*)




%start <binding list> start
%type <binding list> bindingList
%type <binding> binding

%type <expr list> expressionList
%type <expr> expression

%type <expr> application
%type <expr> base

%type <constructor list> declarationsList
%type <constructor> declarations
%type <param list> paramList
%type <param> param

%type <matchbranch list> matchbranch
%type <matchbranch> matchIt
%type <patternvars> patternvars
%type <bop> binop
%type <uop> unop

%type <typ list> typesList
%type <typ> types
%type <typ> baseType


%type <string list> idList

%%

start:
  | b = bindingList; EOF; { b } 
 

bindingList: 
  | bind = binding; DoubleSemicolon; list = bindingList; {bind :: list}
  | bind = binding; DoubleSemicolon; {bind :: []}

binding:
  | Let; id = Id; p = paramList; Colon; t = types; Equal; e1 = expression; {Let(id, p, Some t, e1) }
  | Let; id = Id; p = paramList; Equal; e1 = expression; {Let(id, p, None, e1)}

  | Let; Rec;  id = Id; p = paramList; Colon; t = types; Equal; e1 = expression;{LetRec(id, p, Some t, e1)}
  | Let; Rec; id = Id; p = paramList; Equal; e1 = expression; {LetRec(id, p, None,  e1)}

  | Type; id = Id; Equal; d = declarationsList {TypeDec(id, d)}


declarationsList: 
  | d = declarations; list = declarationsList; {d :: list}
  | d = declarations; {d :: []}

declarations:
  | Pipe; id = Id; Of; t = types; {Declaration(id, Some t)}
  | Pipe; id = Id; {Declaration(id, None)}


paramList: 
  | p = param; list = paramList; {p :: list}
  | {[]}
param: 
  | id = Id; {PString(id, None)}
  | LParen; id = Id; Colon; t = types; RParen {PString(id, Some t)}

expressionList:
  | e1 = expression; Comma; e2 = expressionList; {e1 :: e2}
  | e1 = expression; Comma; e2 = expression; {[e1; e2]}

expression:
  | Let; id = Id; p = paramList; Colon; t = types; Equal; e1 = expression; In; e2 = expression{Let(id, p, Some t, e1, e2)}
  | Let; id = Id; p = paramList; Equal; e1 = expression; In; e2 = expression {Let(id, p, None,  e1, e2)}

  | Let; Rec;  id = Id; p = paramList; Colon; t = types; Equal; e1 = expression; In; e2 = expression{LetRec(id, p, Some t, e1, e2)}
  | Let; Rec; id = Id; p = paramList; Equal; e1 = expression; In; e2 = expression {LetRec(id, p, None, e1, e2)}

  | If; e1 = expression; Then; e2 = expression; Else; e3 = expression; {If(e1,e2,e3)}
  | Fun; p = paramList; Colon; t = types; DoubleArrow; e1 = expression; {Fun(p, Some t, e1)} 
  | Fun; p = paramList; DoubleArrow; e1 = expression; {Fun(p, None, e1)} 
  | Match; e1 = expression; With; m = matchbranch; {Match(e1, m)}
  | LParen; elist = expressionList; RParen {AppList(elist)} 
  | u = unop; e1 = expression; {EUnop(u, e1)}
  | a = application; {a}
  | e1 = application; e2 = base; {App(e1, e2)}

application:
  | e1 = application; b = binop; e2 = application; {EBinop(e1, b, e2)}
  | b = base; {b}
base: 
  | LParen; e1 = expression; RParen; {Paran(e1)}
  | id = Int; {EInt(id)}
  | True; {ETrue}
  | False; {EFalse}
  | str = String; {EString(str)}
  | id = Id; {EId(id)}
  | LParen; RParen; {EUnit}


matchbranch: 
  | Pipe; m = matchIt; m2 = matchbranch; {m :: m2}
  | Pipe; m = matchIt; {m :: []}

matchIt:
  | id = Id; pat = patternvars; DoubleArrow; e1 = expression; {Branch(id, pat, e1)}

idList: 
  | id = Id; list = idList; {id :: list}
  | id = Id; {id :: []}


patternvars:
  | id = idList; {PatternList(id)}
  | {PatternList([])}

%inline
binop:
  | Plus; {Plus}
  | Minus; {Minus}
  | Times; {Times}
  | Divide; {Divide}
  | Mod; {Modulus}
  | Less; {Less}
  | Equal; {Equals}
  | Concat; {Concat}
  | And; {And}
  | Or; {Or}

%inline
unop:
  | Not; {Not}
  | Negate;{Negate}

typesList: 
  | t = baseType; Times; list = typesList; {t :: list}
  | t1 = baseType; Times; t2 = baseType; {[t1 ; t2]}
types:
  | t1 = types; Arrow; t2 = types { FuncTy(t1,t2) }
  | tlist = typesList; {Tuple(tlist)}
  | bt = baseType; {bt}
baseType:
  | LParen; t1 = types; RParen; {Paren(t1)}
  | TInt; Equal; { IntTy }
  | TBool; Equal; { BoolTy }
  | TString; Equal; {StringTy}
  | TUnit; Equal; {UnitTy}
  | id = Id; {EVar(id)}



