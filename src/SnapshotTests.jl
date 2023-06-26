module SnapshotTests

import Test: @test
import Logging: @warn
import Serialization: serialize, deserialize
import Pkg
import GZip: gzopen
import Infiltrator: @infiltrate

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

            # in normal mode, just do a test. But in REPL mode, drop into a REPL for investigating differences.
            if !haskey(ENV, "START_REPL_ON_SNAPSHOT_FAILURE") || lowercase(ENV["START_REPL_ON_SNAPSHOT_FAILURE"]) ∉ ["yes", "true", "1"]
                @test $comparator(observed, expected)
            elseif !($comparator(observed, expected))
                # make observed and expected visible outside the macro
                $(esc(:(observed))) = observed
                $(esc(:(expected))) = expected
                
                @error "Test failed, starting REPL.\nThe observed result is available in the variable `observed`, the expected in the variable `expected`" stacktrace()
                @infiltrate
            end
        end
    end
end

export @snapshot_test

end
