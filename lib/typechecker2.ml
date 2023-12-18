open Ocaml_lite.Ast




module Env = Map.Make(String)

let empty_env = Env.empty

type env = value Env.t
and value = 
  | VUnit
  | VInt
  | VBool
  | VString
  | VTuple of value list
  | VUser of string * value list
  | VBuiltIn of string
  | VConstr of string
  | VClosure of string * value Env.t * expr * string option

let rec typeofvalue t = 
match t with
  | VUnit -> UnitTy
  | VInt -> IntTy
  | VBool -> BoolTy
  | VString -> StringTy
  | VTuple(vList) -> Tuple(helper vList)
  | VUser(s, _) -> EVar(s)
  | _ -> failwith("non-matching types")
and helper vlist = 
match vlist with
| [] -> []
| h :: t -> typeofvalue h :: helper t

let rec typeofbindinglist (bind: binding list) = function
  | _ -> typeofbindinglistpriv empty_env bind
and typeofbindinglistpriv (env: env) (bind: binding list) = 
match bind with
  | [] -> env
  | h :: t -> typeofbindinglistpriv (typeofbinding env h) t
and typeofbinding env binding = 
match binding with 
  | Let (str, pList, None , e) -> typeofbindinglet env str pList e false
  | Let (str, pList, Some t , e) -> if (typeofvalue (typeofexpr env e) =  t) then typeofbindinglet env str pList e false else failwith("failed let binding typecheck")
  | LetRec (str, pList, None, e) -> typeofbindinglet env str pList e true
  | LetRec (str, pList, Some t , e) -> if (typeofvalue (typeofexpr env e) =  t) then typeofbindinglet env str pList e true else failwith("failed letRec binding typecheck")
  | TypeDec(str, cList) -> typeoftypedecList env str cList

and typeoftypedecList (env: env) (str : string) (cList : constructor list) = 
match cList with 
| [] -> env
| h :: t -> typeoftypedecList (typeofdeclaration env str h) str t
(*let env' = Env.add str VConstr(cList) env in env' (*Feel like this almost right should ask Greg*)*)

and typeofdeclaration (env: env) (str : string) (cons : constructor) = 
  match cons with
    | Declaration(id, _) -> Env.add str (VConstr(id)) env (*I'm not quite sure how this should be treated differently*)

and typeofbindinglet (env : env) (str: string) (pList: param list)(e : expr)(isRec: bool)  = 
  match pList with
    | [] -> failwith("failed typeofbindinglet typechecking")
    | h :: t -> if(isRec) then 
      (match h with 
        | PString(s, _) -> Env.add str (VClosure(s, env, Fun(t, None, e), Some str)) env) 
    else 
      (match h with
        | PString(s, _) -> Env.add str (VClosure(s, env,Fun(t, None, e), None)) env)


and typeofexpr (env: env) (e: expr) : value = 
match e with 
    | Let (str, pList, None, e1, e2) -> typeof_let env str (typeoffunc env pList e1) e2
    | Let (str, pList, Some t, e1, e2) -> if (typeofvalue(typeof_let env str (typeoffunc env pList e1) e2) !=  t) then failwith("did not match types for let") else typeof_let env str (typeoffunc env pList e1) e2
    | LetRec (str, pList, _, e1, e2) -> typeof_let env str (typeoffunc env pList e1) e2
    | If(e1, e2, e3) -> typeofif env e1 e2 e3 
    | Fun(pList, None, e1) -> typeoffunc env pList e1
    | Fun(pList, Some t, e1) -> if typeofvalue (typeoffunc env pList e1) != t then failwith("nont matching types in Fun expr") else typeoffunc env pList e1
    | App(e1, e2) -> typeofapp (typeofexpr env e1) (typeofexpr env e2)
    | AppList(eList) -> typeofapplist env eList
    | EBinop(e1, bop, e2) -> typeofbinop env bop e1 e2
    | EUnop(unop, e1) -> typeofunop env unop e1
    | Paran x -> typeofexpr env x
    | EInt _ -> VInt
    | ETrue -> VBool
    | EFalse -> VBool
    | EString _ -> VString
    | EId x -> typeofvar env x
    | EUnit -> VUnit
    | Match(e, mbl) -> typeofmatch env e mbl 
and typeofvar env x = 
  try Env.find x env
  with Not_found -> failwith("Unbound Variable Error")
and typeoffunc env pList e1 =
  match pList with
    | h :: [] -> (match h with 
    | PString (s, _) -> VClosure(s, env, e1, None))
    | h :: t -> 
    (match h with 
      | PString (s, _) -> VClosure(s, env, Fun(t, None, e1), None))
    | [] -> failwith("Anonymous function with no parameters failed typechecking typeof func")
and typeofapplist env eList = 
  match eList with
    | [] -> failwith("failed typechecking an applist")
    | h :: [] -> VTuple(typeofexpr env h :: [])
    | h :: t ->  (let vtup = typeofapplist env t in 
    match vtup with 
    |VTuple(tup) -> VTuple((typeofexpr env h) :: tup)
    | _ -> failwith("failed typechecking an applist")
    )
and typeofapp (v1: value) (v2: value) : value = (*Do I not need env here because they are both values?*)
  match v1 with
    | VClosure(str, environment, expr, Some strOpt) -> 
      let env' = Env.add str v2 environment in 
      let env'' = (Env.add strOpt (VClosure(str, environment, expr, Some strOpt)) env') in typeofexpr env'' expr
    | VClosure(str, environment, expr, None) -> let env' = Env.add str v2 environment in typeofexpr env' expr
    | VConstr(str) -> 
    (match v2 with
      | VTuple(tuple) -> VUser(str, tuple)
      | _ -> VUser(str, v2 :: [])
    )
    | _ -> failwith("applying non-function as first input")
and typeofmatch env e mbl = 
  let value = typeofexpr env e in 
  match value with 
    | VUser(str, vList) -> checkMb env str vList mbl 
    | _ -> failwith("Matchbranch Error")
and checkMb env str vList mbl = 
  match mbl with 
  | h :: t -> (match h with 
    | Branch(s, patvars, exp)  -> if(s = str) then 
    match patvars with 
    | PatternList(sList) -> typeofexpr (addParvarsVList env sList vList) exp else checkMb env str vList t)
  | [] -> failwith("Types doen't match in MBL")


and addParvarsVList env vList mbl = 
  match vList, mbl with 
    | h :: [], head :: [] -> Env.add h head env
    | h :: t, head :: tail -> addParvarsVList (Env.add h head env) t tail
    | _, _ -> failwith("Non matching array sizes in mbl patvars and vlist")

and typeofbinop env bop e1 e2 = 
  match bop, typeofexpr env e1, typeofexpr env e2 with 
    | Plus, VInt, VInt -> VInt
    | Minus, VInt, VInt -> VInt
    | Times, VInt, VInt -> VInt
    | Divide, VInt, VInt -> VInt
    | Modulus, VInt, VInt -> VInt
    | Less, VInt, VInt -> VBool
    | Equals, _, _ -> if(typeofexpr env e1 = typeofexpr env e2) then VBool else failwith("non matching types in equal")
    | And, VBool, VBool -> VBool
    | Or, VBool, VBool -> VBool
    | _, _, _ -> failwith("failed Binop typeofuation")
and typeofunop env unop e1 = 
  match unop, typeofexpr env e1 with
    | Not, VBool  -> VBool
    | Negate, VInt -> VInt
    | _, _ -> failwith("failed Unary typeofuation")
and typeofif env e1 e2 e3 = 
  match typeofexpr env e1 with
    | VBool -> if typeofexpr env e2 = typeofexpr env e3 then typeofexpr env e2 else failwith("non matching types in if statementet")
    | _ -> failwith("tried to pass non-boolean into if clause of if statement")
and typeof_let env str e1 e2 = 
  let env' = Env.add str e1 env in 
  typeofexpr env' e2

