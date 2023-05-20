module SnapshotTests

import Test: @test
import Logging: @warn
import Serialization: serialize, deserialize
import Pkg
import GZip: gzopen

function find_project_dir(dir)
    while !isfile(joinpath(dir, "Project.toml"))
        new_dir = dirname(dir)
        new_dir == dir && error("Did not find Project.toml!")
        dir = new_dir
    end
    return dir
end

macro snapshot_test(file, expr, comparator=isequal, path=nothing)
    return quote
        snapshot_path = if isnothing($path)
            joinpath(find_project_dir(Base.source_dir()), "snapshots", $file * ".gz")
        else
            joinpath($path, $file * ".gz")
        end

        observed = $(esc(expr))

        if !Base.Filesystem.isfile(snapshot_path)
            # snapshot does not exist. Check environment to see if we should create it.
            if !haskey(ENV, "CREATE_NONEXISTENT_SNAPSHOTS") || lowercase(ENV["CREATE_NONEXISTENT_SNAPSHOTS"]) ∉ ["yes", "true", "1"]
                error("Snapshot file $snapshot_path does not exist! Re-run with environment variable CREATE_NONEXISTENT_SNAPSHOTS=yes to create.")
            else
                # create the snapshot file
                @warn "Snapshot file $snapshot_path does not exist, creating."
                if !isdir(dirname(snapshot_path))
                    mkdir(dirname(snapshot_path))
                end

                gzopen(snapshot_path, "w") do fp
                    serialize(fp, observed)
                end
            end
        else
            # snapshot does exist
            expected = gzopen(snapshot_path, "r") do fp
                deserialize(fp)
            end

            @test $comparator(observed, expected)
        end
    end
end

export @snapshot_test

end
