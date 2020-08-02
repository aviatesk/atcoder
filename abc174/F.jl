# %% constants & libraries
# ------------------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and and stuff
    N, Q = readnum()
    c = readnum()
    lrs = [readnum() for _ in 1:Q]

    println.(solve(c, lrs))
end

@inbounds begin

function solve(c, lrs)
    idxs = sortperm(lrs, by = lr -> last(lr))
    lr = 1
    rms = [0 for _ in 1:maximum(c)]
    ret = Int[0 for _ in lrs]

    for idx in idxs
        l, r = lrs[idx]
        ret[idx] = get_and_update!(c, l, r, lr, rms)
        lr = r
    end

    return ret
end

# TODO: speed up this with fenwick tree
function get_and_update!(c, l, r, lr, rms)
    for n in lr:r
        rms[c[n]] = n
    end
    return count(≥(l), rms)
end

end

@static if @isdefined(Juno) || @isdefined(VSCodeServer)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
