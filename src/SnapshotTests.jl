module SnapshotTests

import Test: @test
import Logging: @warn
import Serialization: serialize, deserialize
import Pkg

macro snapshot_test(file, expr, comparator=(==), path=joinpath(dirname(Pkg.project().path), "snapshots"))
    return quote
        snapshot_path = joinpath($path, $file)
        observed = $(esc(expr))
        if !Base.Filesystem.isfile(snapshot_path)
            # snapshot does not exist. Check environment to see if we should create it.
            if !haskey(ENV, "CREATE_NONEXISTENT_SNAPSHOTS") || lowercase(ENV["CREATE_NONEXISTENT_SNAPSHOTS"]) ∉ ["yes", "true", "1"]
                error("Snapshot file $snapshot_path does not exist! Re-run with environment variable CREATE_NONEXISTENT_SNAPSHOTS=yes to create.")
            else
                # create the snapshot file
                @warn "Snapshot file $snapshot_path does not exist, creating."
                if !isdir($path)
                    mkdir($path)
                end

                open(snapshot_path, "w") do fp
                    serialize(fp, observed)
                end
            end
        else
            # snapshot does exist
            expected = open(snapshot_path, "r") do fp
                deserialize(fp)
            end

            @test $comparator(observed, expected)
        end
    end
end

export @snapshot_test

end
