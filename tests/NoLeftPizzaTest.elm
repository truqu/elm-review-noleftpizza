module NoLeftPizzaTest exposing (..)

import NoLeftPizza
import Review.Test
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "NoLeftPizza"
        [ test "Simple pizza" <|
            \_ ->
                """module A exposing (..)

a = foo <| bar"""
                    |> Review.Test.run NoLeftPizza.rule
                    |> Review.Test.expectErrors
                        [ makeError "foo <| bar"
                            |> Review.Test.whenFixed
                                """module A exposing (..)

a = foo bar"""
                        ]
        , test "Nested pizza" <|
            \_ ->
                """module A exposing (..)

a = foo <| bar <| baz"""
                    |> Review.Test.run NoLeftPizza.rule
                    |> Review.Test.expectErrors
                        [ makeError
                            "foo <| bar <| baz"
                            |> Review.Test.whenFixed
                                """module A exposing (..)

a = foo (bar <| baz)"""
                        , makeError "bar <| baz"
                            |> Review.Test.whenFixed
                                """module A exposing (..)

a = foo <| bar baz"""
                        ]
        , test "Fixes operator precedence" <|
            \_ ->
                """module A exposing (..)

a = foo <| 1 + 1"""
                    |> Review.Test.run NoLeftPizza.rule
                    |> Review.Test.expectErrors
                        [ makeError
                            "foo <| 1 + 1"
                            |> Review.Test.whenFixed
                                """module A exposing (..)

a = foo (1 + 1)"""
                        ]
        , test "Fixes more operator precedence" <|
            \_ ->
                """module A exposing (..)

a = foo <| 1 + 1 / 2"""
                    |> Review.Test.run NoLeftPizza.rule
                    |> Review.Test.expectErrors
                        [ makeError
                            "foo <| 1 + 1 / 2"
                            |> Review.Test.whenFixed
                                """module A exposing (..)

a = foo (1 + 1 / 2)"""
                        ]
        , test "Why isn't this fixed?" <|
            \_ ->
                """module A exposing (..)

f =
    List.map .x <| y
"""
                    |> Review.Test.run NoLeftPizza.rule
                    |> Review.Test.expectErrors
                        [ makeError
                            "List.map .x <| y"
                            |> Review.Test.whenFixed
                                """module A exposing (..)

f =
    List.map .x y
"""
                        ]
        , test "Why isn't _this_ fixed, pt2?" <|
            \_ ->
                """module A exposing (..)

f =
    String.join " " <|
        List.map x y
"""
                    |> Review.Test.run NoLeftPizza.rule
                    |> Review.Test.expectErrors
                        [ makeError
                            """String.join " " <|
        List.map x y"""
                            |> Review.Test.whenFixed
                                """module A exposing (..)

f =
    String.join " " (List.map x y)
"""
                        ]
        , test "Why isn't _this_ fixed, pt3?" <|
            \_ ->
                """module A exposing (..)

f =
    String.join " " <|
        List.map
            (\\x ->
                 x
            )
            y
        """
                    |> Review.Test.run NoLeftPizza.rule
                    |> Review.Test.expectErrors
                        [ makeError
                            """String.join " " <|
        List.map
            (\\x ->
                 x
            )
            y"""
                            |> Review.Test.whenFixed
                                """module A exposing (..)

f =
    String.join " " (List.map (\\x -> x)
     y)
        """
                        ]
        , test "handle parser operators with pizza" <|
            \() ->
                """
module MyParser exposing (..)
numberToken =
    Parser.getChompedString <|
        Parser.succeed ()
            |. Parser.chompIf Char.isDigit
            |. Parser.chompWhile Char.isDigit
"""
                    |> Review.Test.run NoLeftPizza.rule
                    |> Review.Test.expectErrors
                        [ makeError """Parser.getChompedString <|
        Parser.succeed ()
            |. Parser.chompIf Char.isDigit
            |. Parser.chompWhile Char.isDigit"""
                            |> Review.Test.whenFixed
                                """
module MyParser exposing (..)
numberToken =
    Parser.getChompedString (Parser.succeed () |. Parser.chompIf Char.isDigit |. Parser.chompWhile Char.isDigit)
"""
                        ]
        , test "handle logic operators with pizza" <|
            \() ->
                """
module A exposing (..)
f =
    if isTrue <| True || False then
        True
    else
        False
"""
                    |> Review.Test.run NoLeftPizza.rule
                    |> Review.Test.expectErrors
                        [ makeError "isTrue <| True || False"
                            |> Review.Test.whenFixed
                                """
module A exposing (..)
f =
    if isTrue (True || False) then
        True
    else
        False
"""
                        ]
        , describe "mixed pizzas" mixedPizzaTests
        ]


mixedPizzaTests : List Test
mixedPizzaTests =
    [ test "a <| (b |> c)" <|
        \() ->
            """
module A exposing (..)
f =
    a <| (b |> c)
"""
                |> Review.Test.run NoLeftPizza.rule
                |> Review.Test.expectErrors
                    [ makeError "a <| (b |> c)"
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
f =
    a (b |> c)
"""
                    ]
    , test "(a <| b) |> c)" <|
        \() ->
            """
module A exposing (..)
f =
    (a <| b) |> c
"""
                |> Review.Test.run NoLeftPizza.rule
                |> Review.Test.expectErrors
                    [ makeError "a <| b"
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
f =
    (a b) |> c
"""
                    ]
    , test "a |> (b <| c)" <|
        \() ->
            """
module A exposing (..)
f =
    a |> (b <| c)
"""
                |> Review.Test.run NoLeftPizza.rule
                |> Review.Test.expectErrors
                    [ makeError "b <| c"
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
f =
    a |> (b c)
"""
                    ]
    , test "(a |> b) <| c" <|
        \() ->
            """
module A exposing (..)
f =
    (a |> b) <| c
"""
                |> Review.Test.run NoLeftPizza.rule
                |> Review.Test.expectErrors
                    [ makeError "(a |> b) <| c"
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
f =
    (a |> b) c
"""
                    ]
    ]


makeError : String -> Review.Test.ExpectedError
makeError under =
    Review.Test.error
        { message = "That's a left pizza (<|) operator application there!"
        , details =
            [ "We prefer using either parenthesized function application like `Html.text (context.translate Foo.Bar)` or right pizza's like `foo |> bar`."
            , "The proposed fix rewrites the expression to a simple parenthesized expression, however, this may not always be what you want. Use your best judgement!"
            ]
        , under = under
        }
