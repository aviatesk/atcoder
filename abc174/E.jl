# %% constants or libraries
# -------------------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and and stuff
    N, K = readnum()
    A = readnum()
    println(solve(N, K, A))
end

function solve(N, K, A)
    function lt(a, b)
        # `b` is always identical to `K`
        k = sum(ceil.(Int, A ./ a) .- 1)
        return isless(b, k) # flip the arguments because `k` decreases as `a` gets bigger
    end
    return searchsortedfirst(1:maximum(A), K; lt = lt)
end

@static if @isdefined(Juno) || @isdefined(VSCodeServer)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
