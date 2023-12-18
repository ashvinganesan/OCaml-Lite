type typ = 
  | FuncTy of typ * typ
  | Paren of typ
  | Tuple of typ list
  | IntTy
  | BoolTy
  | StringTy
  | UnitTy
  | EVar of string 

type uop = 
  | Not
  | Negate
type bop = 
  | Plus
  | Minus
  | Times
  | Divide
  | Modulus
  | Less
  | Equals
  | Concat
  | And
  | Or


type constructor = 
  | Declaration of (string * typ option)

type param = 
  | PString of string * typ option

type expr = 
  | Let of string * param list * typ option * expr * expr 
  | LetRec of string * param list * typ option * expr * expr
  | If of expr * expr * expr
  | Fun of param list * typ option * expr
  | App of expr * expr
  | AppList of expr list
  | EBinop of expr * bop * expr
  | EUnop of uop * expr
  | Paran of expr
  | EInt of int
  | ETrue
  | EFalse
  | EString of string
  | EId of string
  | EUnit
  | Match of expr * matchbranch list

and  matchbranch = 
  | Branch of string * patternvars * expr
and patternvars = 
  | PatternList of string list

  


type binding = 
  | Let of string * param list * typ option * expr
  | LetRec of string * param list * typ option * expr
  | TypeDec of string * constructor list



let rec print_typ_list  (t : typ list)  = 
  match t with
    | [] -> ""
    | h :: t -> (print_typ(h) ^ print_typ_list(t))
and print_pL (pL : param list) = 
  match pL with
    | [] -> ""
    | h :: t -> print_p h ^ print_pL t
and print_p (p : param) = 
  match p with
    | PString(s, Some t) -> s ^ (print_typ t)
    | PString(s, None) -> s
and print_typ : typ -> string = function
  | FuncTy(t1, t2) -> print_typ(t1) ^ print_typ(t2)
  | Paren(t) -> "("^ print_typ(t)^")"
  | Tuple(tL) ->  print_typ_list tL
  | IntTy -> "int"
  | BoolTy -> "bool"
  | StringTy -> "string"
  | UnitTy -> "unit"
  | EVar(s)  -> s
and print_binop : bop -> string = function
  | Plus -> "+"
  | Minus -> "-"
  | Times -> "*"
  | Divide -> "/"
  | Modulus -> "%"
  | Less -> "<"
  | Equals -> "="
  | Concat -> "^"
  | And -> "&&"
  | Or -> "||"
and print_uop : uop -> string = function
  | Not -> "not"
  | Negate -> "~"

and  print_exp_list  (e : expr list)  = 
  match e with
  | [] -> ""
  | h :: t -> (print_expr(h) ^ print_exp_list(t))
and print_matchbList (b : matchbranch list) =
  match b with 
    | [] -> ""
    | h :: t -> (print_matchb(h) ^ print_matchbList(t))
and print_matchb: matchbranch -> string = function
  | Branch(s, pattern, ex) -> s ^ print_pattern pattern ^ print_expr(ex)

and print_pattern : patternvars -> string = function 
  | PatternList(sList) -> print_string_list(sList)
and print_string_list(s : string list) =
  match s with
  | [] -> ""
  | h :: t -> h ^ print_string_list(t)
and print_expr : expr -> string = function
  | Let(s, pL, Some t, e1, e2) -> s ^ (print_pL pL) ^(print_typ t) ^ (print_expr e1) ^ (print_expr e2)
  | Let(s, pL, None, e1, e2) ->s ^ (print_pL pL) ^ (print_expr e1) ^ (print_expr e2)
  | LetRec(s, pL, Some t, e1, e2) -> s ^ (print_pL pL) ^(print_typ t) ^ (print_expr e1) ^ (print_expr e2)
  | LetRec(s, pL, None, e1, e2) ->s ^ (print_pL pL) ^ (print_expr e1) ^ (print_expr e2)
  | If(e1, e2, e3) -> "if " ^ print_expr(e1) ^ " then " ^print_expr(e2) ^ " else " ^ print_expr(e3)
  | Fun(pL, Some t, e1) -> (print_pL pL) ^ (print_typ t) ^ (print_expr e1)
  | Fun(pL, None, e1) -> (print_pL pL) ^ (print_expr e1)
  | App(e1,e2) -> print_expr(e1) ^ print_expr(e2)
  | AppList(eL) -> print_exp_list(eL)
  | EBinop(e1,b,e2) -> print_expr(e1) ^ print_binop(b) ^ print_expr(e2)
  | EUnop (u, e1) -> print_uop(u) ^ print_expr(e1)
  | Paran(e) -> "("^ print_expr(e)^")"
  | EInt(i) -> string_of_int(i)
  | ETrue -> "true"
  | EFalse -> "false"
  | EString(s) -> s
  | EId(s) -> s
  | EUnit -> "()"
  | Match(e, mbL) -> print_expr(e) ^ print_matchbList(mbL)
and print_binding: binding -> string = function
  | Let(s, pL, Some t, e1) -> s ^ (print_pL pL) ^(print_typ t) ^ (print_expr e1) 
  | Let(s, pL, None, e1) ->s ^ (print_pL pL) ^ (print_expr e1) 
  | LetRec(s, pL, Some t, e1) -> s ^ (print_pL pL) ^(print_typ t) ^ (print_expr e1) 
  | LetRec(s, pL, None, e1) ->s ^ (print_pL pL) ^ (print_expr e1)
  | TypeDec(s, constructorList) -> s ^ print_constructor_list(constructorList)
and print_binding_list (b : binding list) =
  match b with 
  | [] -> ""
  | h ::t -> print_binding(h) ^ print_binding_list(t)
and print_constructor_list (c : constructor list) =
  match c with 
  | [] -> ""
  | h ::t -> print_constructor(h) ^ print_constructor_list(t)
and print_constructor: constructor -> string = function
  | Declaration(s, Some t) -> s ^ print_typ(t)
  | Declaration(s, None) -> s

