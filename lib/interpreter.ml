open Ocaml_lite.Ast




module Env = Map.Make(String)

let empty_env = Env.empty

type env = value Env.t
and value = 
  | VUnit
  | VInt of int
  | VBool of bool
  | VString of string
  | VTuple of value list
  | VUser of string * value list
  | VBuiltIn of string
  | VConstr of string
  | VClosure of string * value Env.t * expr * string option


let rec evalbindinglist (bind: binding list) = function
  | _ -> evalbindinglistpriv empty_env bind
and evalbindinglistpriv (env: env) (bind: binding list) = 
match bind with
  | [] -> env
  | h :: t -> evalbindinglistpriv (evalbinding env h) t
and evalbinding env binding = 
match binding with 
  | Let (str, pList, _ , e) -> evalbindinglet env str pList e false
  | LetRec (str, pList, _, e) -> evalbindinglet env str pList e true
  | TypeDec(str, cList) -> evaltypedecList env str cList

and evaltypedecList (env: env) (str : string) (cList : constructor list) = 
match cList with 
| [] -> env
| h :: t -> evaltypedecList (evaldeclaration env str h) str t
(*let env' = Env.add str VConstr(cList) env in env' (*Feel like this almost right should ask Greg*)*)

and evaldeclaration (env: env) (str : string) (cons : constructor) = 
  match cons with
    | Declaration(id, _) -> Env.add str (VConstr(id)) env

and evalbindinglet (env : env) (str: string) (pList: param list)(e : expr)(isRec: bool)  = 
  match pList with
    | [] -> failwith("should not have reached this case")
    | h :: t -> if(isRec) then 
      (match h with 
        | PString(s, _) -> Env.add str (VClosure(s, env, Fun(t, None, e), Some str)) env) 
    else 
      (match h with
        | PString(s, _) -> Env.add str (VClosure(s, env,Fun(t, None, e), None)) env)


and evalexpr (env: env) (e: expr) : value = match e with 
    | Let (str, pList, _, e1, e2) -> eval_let env str (evalfunc env pList e1) e2
    | LetRec (str, pList, _, e1, e2) -> eval_let env str (evalfunc env pList e1) e2
    | If(e1, e2, e3) -> evalif env e1 e2 e3 
    | Fun(pList, _, e1) -> evalfunc env pList e1
    | App(e1, e2) -> evalapp (evalexpr env e1) (evalexpr env e2) (*Maybe I should be evaluating e2 to be a value so i can easily deal with the case below*)
    | AppList(eList) -> evalapplist env eList
    | EBinop(e1, bop, e2) -> evalbinop env bop e1 e2
    | EUnop(unop, e1) -> evalunop env unop e1
    | Paran x -> evalexpr env x
    | EInt a -> VInt a
    | ETrue -> VBool true
    | EFalse -> VBool false
    | EString s -> VString s
    | EId x -> evalvar env x
    | EUnit -> VUnit
    | Match(e, mbl) -> evalmatch env e mbl (*should this be type VConstr or VBuiltin should ask greg*)
and evalvar env x = 
  try Env.find x env
  with Not_found -> failwith("Unbound Variable Error")
and evalfunc env pList e1 =
  match pList with
    | h :: [] -> (match h with 
    | PString (s, _) -> VClosure(s, env, e1, None))
    | h :: t -> 
    (match h with 
      | PString (s, _) -> VClosure(s, env, Fun(t, None, e1), None))
    | [] -> failwith("Anonymous function with no parameters")
and evalapplist env eList = 
  match eList with
    | [] -> failwith("should have failed typechecking")
    | h :: [] -> VTuple(evalexpr env h :: [])
    | h :: t ->  (let vtup = evalapplist env t in 
    match vtup with 
    |VTuple(tup) -> VTuple((evalexpr env h) :: tup)
    | _ -> failwith("Should not reach this case :/")
    )
and evalapp (v1: value) (v2: value) : value = (*Do I not need env here because they are both values?*)
  match v1 with
    | VClosure(str, environment, expr, Some strOpt) -> 
      let env' = Env.add str v2 environment in 
      let env'' = (Env.add strOpt (VClosure(str, environment, expr, Some strOpt)) env') in evalexpr env'' expr
    | VClosure(str, environment, expr, None) -> let env' = Env.add str v2 environment in evalexpr env' expr
    | VConstr(str) -> 
    (match v2 with
      | VTuple(tuple) -> VUser(str, tuple)
      | _ -> VUser(str, v2 :: [])
    )
    | _ -> failwith("applying non-function as first input")
and evalmatch env e mbl = 
  let value = evalexpr env e in 
  match value with 
    | VUser(str, vList) -> checkMb env str vList mbl 
    | _ -> failwith("Matchbranch Error")
and checkMb env str vList mbl = 
  match mbl with 
  | h :: t -> (match h with 
    | Branch(s, patvars, exp)  -> if(s = str) then 
    match patvars with 
    | PatternList(sList) -> evalexpr (addParvarsVList env sList vList) exp else checkMb env str vList t)
  | [] -> failwith("Nothing matches mbl")


and addParvarsVList env vList mbl = 
  match vList, mbl with 
    | h :: [], head :: [] -> Env.add h head env
    | h :: t, head :: tail -> addParvarsVList (Env.add h head env) t tail
    | _, _ -> failwith("Non matching array sizes in mbl patvars and vlist")

and evalbinop env bop e1 e2 = 
  match bop, evalexpr env e1, evalexpr env e2 with 
    | Plus, VInt a, VInt b -> VInt(a+b)
    | Minus, VInt a, VInt b -> VInt(a-b)
    | Times, VInt a, VInt b -> VInt(a*b)
    | Divide, VInt a, VInt b -> VInt(a/b)
    | Modulus, VInt a, VInt b -> VInt(a mod b)
    | Less, VInt a, VInt b -> VBool(a < b)
    | Equals, _, _ -> if(evalexpr env e1 = evalexpr env e2) then VBool(true) else VBool(false)
    | And, VBool a, VBool b -> VBool(a && b)
    | Or, VBool a, VBool b -> VBool(a || b)
    | _ -> failwith("failed Binop evaluation")
and evalunop env unop e1 = 
  match unop, evalexpr env e1 with
    | Not, VBool b  -> VBool(not b)
    | Negate, VInt a -> VInt(a * -1)
    | _, _ -> failwith("failed Unary evaluation")
and evalif env e1 e2 e3 = 
  match evalexpr env e1 with
    | VBool b -> if (b) then evalexpr env e2 else evalexpr env e3
    | _ -> failwith("tried to pass non-boolean into if clause of if statement")
and eval_let env str e1 e2 = 
  let env' = Env.add str e1 env in 
  evalexpr env' e2

