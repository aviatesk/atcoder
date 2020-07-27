# %% constants
# ------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and stuff
    N, = readnum()
    A = readnum()
    println(solve(N, A))
end

@inbounds function solve(N, A)
    p::Int = 1_000
    nstock::Int = 0

    buy(Ai) = (nstock, p = divrem(p, Ai))
    function sell(Ai)
        p += nstock * Ai
        nstock = 0
    end

    for (Ai, d) in zip(A, diff(A))
        if d ≥ 0
            iszero(nstock) && buy(Ai)
        else
            iszero(nstock) || sell(Ai)
        end
    end

    iszero(nstock) || sell(A[end])

    return p
end

@static if @isdefined(Juno)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
