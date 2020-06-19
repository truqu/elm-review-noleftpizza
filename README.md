# elm-review-noleftpizza

Prohibits (redundant/all) use of the left pizza (`<|`) operator and helps
rewriting expressions that use them.

Redundant application of `<|` adds visual noise and may make things harder to
read. For some people, it might act as a visual separator, which is completely
fine!

## Configuration

To allow `<|` only when extra parentheses would need to be added in order to
remove `<|` - in other words, to only flag redundant left pizzas, pass the
`NoLeftPizza.Redundant` flag to the rule:

```elm
import NoLeftPizza
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ NoLeftPizza.rule NoLeftPizza.Redundant
    ]
```

If you wish to go all in and remove any and all left pizza's, you can pass
`NoLeftPizza.Any` instead:

```elm
import NoLeftPizza
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ NoLeftPizza.rule NoLeftPizza.Any
    ]
```

## Rationale for `NoLeftPizza.Any`

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
