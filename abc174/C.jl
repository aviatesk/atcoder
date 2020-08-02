# %% constants
# ------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and and stuff
    K, = readnum()
    println(solve(K))
end

function solve(K)
    n = 1
    while (s = sevens(n)) < K
        n += 1
    end
end

sevens(n) = n ≤ 0 ? 0 : sevens(n-1) + 7*10^(n-1)

@static if @isdefined(Juno) || @isdefined(VSCodeServer)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
