module NoLeftPizza exposing (rule)

{-|

@docs rule

-}

import Elm.Syntax.Declaration exposing (Declaration)
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Infix exposing (InfixDirection)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range as Range
import Review.Fix as Fix
import Review.Rule as Rule exposing (Direction, Error, Rule)
import Util


{-| Forbids using the left pizza operator (<|) in infix position.

Expressions like `foo <| "hello" ++ world` will be flagged, and a fix will be
proposed to write the expression to `foo ("hello" ++ world)`.

To use this rule, add it to your `elm-review` config like so:

    module ReviewConfig exposing (config)

    import NoLeftPizza
    import Review.Rule exposing (Rule)

    config : List Rule
    config =
        [ NoLeftPizza.rule
        ]

If you would prefer to keep writing tests in the more "traditional" style which
uses `<|`, you can disable the rule for `tests/` like so:

    module ReviewConfig exposing (config)

    import NoLeftPizza
    import Review.Rule exposing (Rule)

    config : List Rule
    config =
        [ NoLeftPizza.rule
            |> Rule.ignoreErrorsForDirectories
                [ -- Test functions are traditionally built up using a left pizza.
                  -- While we don't want them in our regular code, let's allow them
                  -- just for tests.
                  "tests/"
                ]
        ]

-}
rule : Rule
rule =
    Rule.newModuleRuleSchema "NoLeftPizza" ()
        |> Rule.withSimpleExpressionVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


expressionVisitor : Node Expression -> List (Error {})
expressionVisitor node =
    case Node.value node of
        Expression.OperatorApplication "<|" _ left right ->
            [ makeError node left right ]

        _ ->
            []


makeError : Node Expression -> Node Expression -> Node Expression -> Error {}
makeError node left right =
    Rule.errorWithFix
        { message = "That's a left pizza (<|) operator application there!"
        , details =
            [ "We prefer using either parenthesized function application like `Html.text (context.translate Foo.Bar)` or right pizza's like `foo |> bar`."
            , "The proposed fix rewrites the expression to a simple parenthesized expression, however, this may not always be what you want. Use your best judgement!"
            ]
        }
        (Node.range node)
        [ Fix.replaceRangeBy (Node.range node)
            (Util.expressionToString (Node.range node)
                (Expression.Application
                    [ left
                    , parenthesize right
                    ]
                )
            )
        ]


parenthesize : Node Expression -> Node Expression
parenthesize ((Node.Node range value) as node) =
    case value of
        Expression.UnitExpr ->
            node

        Expression.FunctionOrValue _ _ ->
            node

        Expression.Operator _ ->
            node

        Expression.Integer _ ->
            node

        Expression.Hex _ ->
            node

        Expression.Floatable _ ->
            node

        Expression.Literal _ ->
            node

        Expression.CharLiteral _ ->
            node

        Expression.TupledExpression _ ->
            node

        Expression.ParenthesizedExpression _ ->
            node

        Expression.RecordExpr _ ->
            node

        Expression.ListExpr _ ->
            node

        Expression.RecordAccess _ _ ->
            node

        Expression.RecordAccessFunction _ ->
            node

        Expression.RecordUpdateExpression _ _ ->
            node

        _ ->
            Node.Node range (Expression.ParenthesizedExpression node)
