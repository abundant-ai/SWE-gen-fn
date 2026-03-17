Elixir v1.19 emits a warning about struct updates where pattern matching is sufficient to catch typing errors, suggesting an optional conversion from a struct update to a map update. The warning includes a multi-line hint with example code. Currently, the example uses an abbreviated placeholder function name ("some_fun" / "some_fun()"), which can be confusing or look unidiomatic to newcomers.

Update the warning text so that the example consistently uses the non-abbreviated name "some_function" (i.e., "some_function()") instead of "some_fun" wherever it appears in the hint.

When this warning is produced, the hint should read like:

    user = some_function()
    %User{user | name: "John Doe"}

and later:

    %User{} = user = some_function()
    %{user | name: "John Doe"}

Expected behavior: any warning/hint message that previously printed "some_fun" as part of this struct-update guidance should now print "some_function" exactly, with the rest of the warning unchanged.

Actual behavior: the warning/hint currently prints "some_fun" in the example code snippet.