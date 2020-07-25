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
    XYP = [readnum() for _ in 1:N]
    # println.(solve(N, XYP))
end

function solve(N, XYP)
    Xpool = Dict{Int,Int}()
    Ypool = Dict{Int,Int}()
    for (X, Y, P) in XYP
        Xpool[X] = get(Xpool, X, 0) + P
        Ypool[Y] = get(Ypool, Y, 0) + P
    end

    ret = zeros(Int, N + 1)
    for i in 1:(N+1)
        Xmax = maximum(findmax, Xpool)
    end
    return ret
end

@static if @isdefined(Juno)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
