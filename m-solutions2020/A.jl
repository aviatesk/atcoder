# %% constants
# ------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and stuff
    X, = readnum()
    println(solve(X))
end

solve(X) = 400 ≤ X ≤ 599 ? 8 :
                 X ≤ 799 ? 7 :
                 X ≤ 999 ? 6 :
                 X ≤ 1199 ? 5 :
                 X ≤ 1399 ? 4 :
                 X ≤ 1599 ? 3 :
                 X ≤ 1799 ? 2 :
                 X ≤ 1999 ? 1 :
                 nothing # should never happen, just here as a fallback

@static if @isdefined(Juno)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
