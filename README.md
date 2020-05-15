# elm-review-noleftpizza

Prohibits the use of the left pizza (`<|`) operator and helps rewriting
expressions that use them to a parenthesized version (if those are even
necessary!)

## Rationale

Our team writes vastly more application code than we write test code. Within our
application code, we have - for quite a long time - enforced the rule that `<|`
left pizza is a sad pizza. The one and only exception is in test code, where we
prefer to stick to the generally accepted style (`test "description" <| \_ ->
...`).

So, this is an interesting case. The docs call out this specific example as the
type of rule that would need very careful consideration before inclusion. And
considered, we have. Carefully, too!

For our specific codebase, we choose to remove noise from our code reviews and
automate that part of the process by enforcing a `NoLeftPizza` rule, for
everything other than tests.

You should likely very carefully consider and evaluate the pros and cons before
enabling this rule on your codebase.

Like any stylistic choice, it is not for everyone.

## Configuration

```elm
module ReviewConfig exposing (config)

import NoLeftPizza
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ NoLeftPizza.rule
        -- The next bit is optional, but just to illustrate how we use it.
        |> Rule.ignoreErrorsForDirectories
            [ -- Test functions are traditionally built up using a left pizza.
              -- While we don't want them in our regular code, let's allow them
              -- just for tests.
              "tests/"
            ]
    ]
```
