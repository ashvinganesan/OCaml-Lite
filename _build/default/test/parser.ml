open OUnit2
open Ocaml_lite.Parser
open Ocaml_lite.Lexer
open Ocaml_lite.Ast

let parse_tests = "test suite for parser" >::: [
    "Binop_test" >::
    (fun _ -> assert_equal ~printer:print_binding_list
        [(Let("a", [], None, (EBinop (ETrue, And ,EFalse))))]
        (parse "let a = true && false;;"));
    (*
    "application" >::
    (fun _ -> assert_equal ~printer:print_binding
        (EApp (ELambda ("x", (EVar "x")), EVar "y"))
        (parse "(&x.x) y"));
    "apply inside lambda" >::
    (fun _ -> assert_equal ~printer:print_binding
        (ELambda ("x", EApp (EVar "x", EVar "y")))
        (parse "&x.x y"));
    "naming" >::
    (fun _ -> assert_equal ~printer:print_binding
        (EApp (ELambda ("fun", (EApp (EVar "fun", EVar "v"))),
               ELambda ("x", ELambda ("y", EVar "x"))))
        (parse "fun = &x. &y. x; fun v"));

    *)
    (*"naming church numerals" >::
    (fun _ -> assert_equal ~printer:print_binding
        (EApp
           (ELambda
              ("zero",
               EApp
                 (ELambda
                   ("succ",
                    EApp (EVar "succ", EApp (EVar "succ", EVar "zero"))),
                 (ELambda
                    ("n",
                     ELambda
                       ("f",
                        ELambda
                          ("x",
                           EApp (EVar "f",
                                 EApp (EApp (EVar "n", EVar "f"),
                                       EVar "x")))))))),
         (ELambda ("f", ELambda ("x", EVar "x")))))
        (parse ("zero = &f. &x. x;" ^
                "succ = &n. &f. &x. f (n f x);" ^
                "succ (succ zero)")));*)
  ]

  