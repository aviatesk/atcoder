# %% constants & libraries
# ------------------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))::Vector{T}

    # handle IO and solve
    N, = readnum()
    A = readnum()
    println(solve(N, A))
end

function solve(N, A)
    ret = 0
    m = typemin(Int)
    for Ai in A
        if m > Ai
            ret += m - Ai
        else
            m = Ai
        end
    end
    return ret
end

@static if @isdefined(Juno) || @isdefined(VSCodeServer)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
