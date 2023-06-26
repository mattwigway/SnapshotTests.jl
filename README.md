# SnapshotTests

Sometimes, when writing automated tests, rather than specifying the value to compare against you want to compare against a "snapshot". This package provides the `@snapshot_test` macro, which compares the result of an expression against a snapshot. Snapshot testing is often discouraged, because you're not really testing that the code produces the expected output, only that the output doesn't change. But in cases with complex outputs, it may be most useful to manually inspect the output of the function once, and then simply assert that it does not change.

## Usage

To create a snapshot test, add to your test file:

```{julia}
@snapshot_test "test_name" expression
```

This will compute `expression`, and compare the result against a serialized value (the snapshot). By default, snapshots will be found in `$JULIA_PROJECT/snapshots`. Within that folder, there will be one snapshot for each snapshot test, serialized using the built-in Julia `Serialization` module and gzipped.

### Creating snapshots

The first time you run the code above, you'll get an error:

```
ERROR: Snapshot file .../snapshots/test_name.gz does not exist! Re-run with environment variable CREATE_NONEXISTENT_SNAPSHOTS=yes to create.
```

This is expected—when you first create the test, there's nothing to compare the value against. As the error message indicates, if you re-run with the environment variable `CREATE_NONEXISTENT_SNAPSHOTS=yes`, the snapshot file will be created. You should investigate that the snapshotted value is correct before committing the snapshot file to version control.

`SnapshotTests` will only ever create a snapshot file that does not exist; it will _never_ overwrite an existing snapshot file. This is to avoid inadvertently updating old snapshot to include unwanted results when creating new snapshots. To update a snapshot, just delete the serialized file from the `snapshots/` directory, and update the snapshots again.

`Base.isequal(result, expected)` must be `true` for a snapshot test to pass. Structs are [only equal if their fields are identity-equal (not value-equal)](https://discourse.julialang.org/t/surprising-struct-equality-test/4890). The [StructEquality.jl](https://github.com/jolin-io/StructEquality.jl) library is often helpful for creating value based `isequal` functions.

You can also specify a custom comparator at the end of the `@snapshot_test` macro. For instance, to use `isapprox`:

```{julia}
@snapshot_test "test_name" expression (isapprox)
```

Parentheses are optional but improve readability IMHO.

### Dealing with failed snapshot tests (not yet released)

Normally, failed snapshot tests result in test failures (as one would expect). However, debugging failed snapshot tests can be difficult, as there is just a yes/no indication of equality with what is almost certainly a complex object. If you start the tests from the REPL (not by running `]test`, but by running `include("runtests.jl")`), and have the environment variable `START_REPL_ON_SNAPSHOT_FAILURE=yes`, [Infiltrator.jl](https://github.com/JuliaDebug/Infiltrator.jl) will be used to start a REPL with the variables `observed` (what the test code produced) and `expected` (what was read in from the snapshot) to evaluate the differences interactively.

If you determine that the changes are as expected, you can delete the snapshot files and recreate them (see above). However, my preference is to instead write a custom comparator function that returns true if all of the differences are as expected, ensure the test passes with the custom comparator, commit the custom comparator to the repository to document the expected changes, and then delete and recreate the snapshots and restore the original comparator. This avoids testing being based on results in an interactive session, which is a bad practice—though certainly useful to debug as a precursor to writing the custom comparator.

Actually starting the tests interactively is a challenge because the test environment is created on the fly by combining the project environment with the test environment. [TestEnv.jl](https://github.com/JuliaTesting/TestEnv.jl) can solve this problem, as it allows activating the test environment of the active project. To avoid installing it as a dependency in my main project, I prefer to install it in the global environment and load it before activating my package. So a full interactive testing run would look something like this:

```
my-project $ START_REPL_ON_SNAPSHOT_FAILURE=yes julia
julia> import TestEnv
(@v1.9) pkg> ]activate .
julia> TestEnv.activate()
julia> include("test/runtests.jl")
```