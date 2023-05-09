# SnapshotTests

Sometimes, when writing automated tests, rather than specifying the value to compare against you want to compare against a "snapshot". This package provides the `@snapshot_test` macro, which compares the result of an expression against a snapshot. Snapshot testing is often discouraged, because you're not really testing that the code produces the expected output, only that the output doesn't change. But in cases with complex outputs, it may be most useful to manually inspect the output of the function once, and then simply assert that it does not change.

## Usage

To create a snapshot test, add to your test file:

```{julia}
@snapshot_test "test_name" expression
```

This will compute `expression`, and compare the result against a serialized value (the snapshot). By default, snapshots will be found in `$JULIA_PROJECT/snapshots`. Within that folder, there will be one snapshot for each snapshot test, serialized using the built-in Julia `Serialization` module.

### Creating snapshots

The first time you run the code above, you'll get an error:

```
ERROR: Snapshot file .../snapshots/myfile5 does not exist! Re-run with environment variable CREATE_NONEXISTENT_SNAPSHOTS=yes to create.
```

This is expected—when you first create the test, there's nothing to compare the value against. As the error message indicates, if you re-run with the environment variable `CREATE_NONEXISTENT_SNAPSHOTS=yes`, the snapshot file will be created. You should investigate that the snapshotted value is correct before committing the snapshot file to version control.

`SnapshotTests` will only ever create a snapshot file that does not exist; it will _never_ overwrite an existing snapshot file. This is to avoid inadvertently updating old snapshot to include unwanted results when creating new snapshots. To update a snapshot, just delete the serialized file from the `snapshots/` directory, and update the snapshots again.