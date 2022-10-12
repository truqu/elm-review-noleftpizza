module Util exposing (expressionToString)

import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Elm.Writer as Writer


expressionToString : Range -> Expression -> String
expressionToString range expr =
    Node.Node range expr
        |> Writer.writeExpression
        |> Writer.write
        -- To make things more parseable by our dear old elm-format, we indent all extra
        -- lines so they appear to the right of where we're starting at
        |> reindent range.start.column


reindent : Int -> String -> String
reindent amount =
    String.lines >> String.join ("\n" ++ String.repeat (amount - 1) " ")
