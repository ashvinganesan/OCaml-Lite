
(* The type of tokens. *)

type token = 
  | With
  | Type
  | True
  | Times
  | Then
  | TUnit
  | TString
  | TInt
  | TBool
  | String of (string)
  | Rec
  | RParen
  | Plus
  | Pipe
  | Or
  | Of
  | Not
  | Negate
  | Mod
  | Minus
  | Match
  | Let
  | Less
  | LParen
  | Int of (int)
  | In
  | If
  | Id of (string)
  | Fun
  | False
  | Equal
  | Else
  | EOF
  | DoubleSemicolon
  | DoubleArrow
  | Divide
  | Concat
  | Comma
  | Colon
  | Arrow
  | And

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val start: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.binding list)
