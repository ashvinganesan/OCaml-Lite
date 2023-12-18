(*open Ocaml_lite.Ast


let empty = []
let unbound_var_err = "Unbound Variable Error"



let lookup env e = 
  match List.assoc_opt e env with 
    | Some t -> t
    | None -> failwith unbound_var_err 


let extends env str (t: typ) = 
  (str, t) :: env


(*let rec  typeofbindingList (bindingList: binding list)= function
  | _ -> typeofbindingListpriv empty bindingList
and typeofbindingListpriv env bindingList = 
match bindingList with
  | [] -> env
  | h :: t -> (typeofbinding env h)
and typeofbinding (env: env) (bind: binding) = 
  | Let (str, pList, Some t, e1) -> failwith("TODO") 
  | Let (str, pList, None, e1) -> failwith("TODO")
  | LetRec (str, pList, Some t, e1) -> failwith("TODO")
  | LetRec(str, pList, None, e1) -> failwith("TODO")
  | TypeDec(str, cList) -> failwith("TODO")
  | _ -> failwith("TODO")

and typeofconstructor env = function
| Declaration(id, Some t) -> failwith("TODO")
| Declaration(id, None) -> failwith("TODO")
| _ -> failwith("Unbound declaration")*)

let rec typeofbindinglist (bind: binding list) = function
  | _ -> typeofbindinglistpriv empty bind
and typeofbindinglistpriv (env: (string * typ) list) (bind: binding list) = 
match bind with
  | [] -> env
  | h :: t -> typeofbindinglistpriv (typeofbinding env h) t
and typeofbinding env binding = 
match binding with 
  | Let (str, pList, Some t , e) -> if (t != (typeofbindinglet env str pList e false)) then failwith("binding doesn't match specified type") else (str, typeofbindinglet env str pList e false) :: env 
  | Let (str, pList, None, e) -> (str, typeofbindinglet env str pList e false) :: env
  | LetRec (str, pList, Some t, e) -> if (t != (typeofbindinglet env str pList e true)) then failwith("binding doesn't match specified type") else (str, typeofbindinglet env str pList e true) :: env
  | LetRec(str, pList, None, e) -> (str, typeofbindinglet env str pList e true) :: env
  | TypeDec(str, cList) -> typeoftypedecList env str cList

and typeoftypedecList (env) (str : string) (cList : constructor list) = 
match cList with 
| [] -> env
| h :: t -> typeoftypedecList (typeofdeclaration env str h) str t
(*let env' = Env.add str VConstr(cList) env in env' (*Feel like this almost right should ask Greg*)*)

and typeofdeclaration (env) (str : string) (cons : constructor) = 
  match cons with
    | Declaration(id, _) -> extends env str (EVar(id))

and typeofbindinglet (env) (str: string) (pList: param list)(e : expr)(isRec: bool)  = 
  match pList with
    | [] -> failwith("Tried do binding list without param")
    | h :: t -> if(isRec) then 
      (match h with 
        | PString(s, _) -> FuncTy(Tuple(pList), typeofexpr env e))
    else 
      (match h with
        | PString(s, _) -> (VClosure(s, env,Fun(t, None, e), None)))
and typeofexpr env (e: expr) = 
  match e with
    | Let (str, _, Some t, e1, e2) -> typeof_let_type env str t e1 e2
    | Let (str, _, None, e1, e2) -> typeof_let env str e1 e2
    | LetRec (str, _, Some t, e1, e2) -> typeof_let_type env str t e1 e2
    | LetRec(str, _, None, e1, e2) -> typeof_let env str e1 e2
    | If(e1, e2, e3) -> typeof_if env e1 e2 e3 (*e1 is bool , e2 and e3 must match*)
    | Fun(pList, Some t, e1) -> if(typeof_func env pList e1 != t) then failwith("typed fun doesn't match") else typeof_func env pList e1
    | Fun(pList, None, e1) -> typeof_func env pList e1
    | App(e1, e2) -> typeof_app env e1 e2
    | AppList(eList) -> Tuple(typeof_applist env eList)
    | EBinop(e1, bop, e2) -> typeof_binop env bop e1 e2
    | EUnop(unop, e1) -> typeof_unop env unop e1
    | Paran x -> typeofexpr env x
    | EInt _ -> IntTy
    | ETrue -> BoolTy
    | EFalse -> BoolTy
    | EString _ -> StringTy
    | EId x -> lookup env x
    | EUnit -> UnitTy
    | Match(e, mbl) -> typeof_match env e mbl
    | _ -> failwith("Not Matched")
and typeof_func env pList e1 =
match pList with
  | h :: [] -> (match h with 
  | PString (s, Some t) -> if (t != lookup env s) then failwith("NON matching type in func") else FuncTy(t, typeofexpr env e1)
  | PString(s, None) -> FuncTy(lookup env s, typeofexpr env e1))
  | h :: tail -> 
  (match h with 
    | PString (s, Some t) -> if (t != lookup env s) then failwith("NON matching type in func") else FuncTy(t, typeofexpr env e1)
    | PString(s, None) -> FuncTy(lookup env s, typeofexpr env e1))
    | _ -> failwith ("no pstring typed failed")
  | [] -> failwith("Anonymous function with no parameters failed typechecking")

  
and typeof_applist env eList = 
  match eList with
    | [] -> failwith("can't get empty appList")
    | h :: [] -> (typeofexpr env h) :: []
    | h :: t ->  (typeofexpr env h) :: (typeof_applist env t)

and typeof_app env e1 e2 = 
  FuncTy(typeofexpr env e1, typeofexpr env e2)

and typeof_match env e mbl = 
  let t' = typeofexpr env e in 
  match t' with 
    | VUser(str, vList) -> checkMb env str vList mbl 
    | _ -> failwith("Non VUser passed to mbl")
and checkMb env str vList mbl = 
  match mbl with 
  | h :: t -> (match h with 
    | Branch(s, patvars, exp)  -> if(s = str) then 
    match patvars with 
    | PatternList(sList) -> typeofexpr (addParvarsVList env sList vList) exp else checkMb env str vList t)
  | [] -> failwith("Nothing matches mbl")

and addParvarsVList env vList mbl = 
  match vList, mbl with 
    | h :: [], head :: [] -> extends env h head 
    | h :: t, head :: tail -> addParvarsVList (extends env h head ) t tail
    | _, _ -> failwith("Non matching array sizes in mbl patvars and vlist")
and typeof_binop env bop e1 e2 = 
  match bop, typeofexpr env e1, typeofexpr env e2 with 
    | Plus, IntTy, IntTy -> IntTy
    | Minus, IntTy, IntTy -> IntTy
    | Times, IntTy, IntTy -> IntTy
    | Divide, IntTy, IntTy -> IntTy
    | Modulus, IntTy, IntTy -> IntTy
    | Less, IntTy, IntTy -> BoolTy
    | Equals, _, _ -> if(typeofexpr env e1 = typeofexpr env e2) then BoolTy else failwith("Non matching Types in Equal Clause")
    | Concat, StringTy, StringTy -> StringTy
    | And, BoolTy, BoolTy -> BoolTy
    | Or, BoolTy, BoolTy -> BoolTy

    | _ -> failwith("failed Binop typechecking")
and typeof_unop env unop e1 = 
  match unop, typeofexpr env e1 with
    | Not, BoolTy  -> BoolTy
    | Negate, IntTy -> IntTy
    | _, _ -> failwith("failed Unary typechecking")
and typeof_if env e1 e2 e3 = 
  match typeofexpr env e1 with
    | BoolTy -> if (typeofexpr env e2 = typeofexpr env e3) then typeofexpr env e2 else failwith("non matching type branches of if statement")
    | _ -> failwith("tried to pass non-boolean into if clause of if statement")
and typeof_let env str e1 e2 = 
  let t' = typeofexpr env e1 in 
    let env' = extends env str t' in
    typeofexpr env' e2
and typeof_let_type env str t e1 e2 = 
  let t' = typeofexpr env e1 in 
  if t = t' then
    let env' = extends env str t' in
    typeofexpr env' e2
  else
    failwith("Type checking error in let")

*)
