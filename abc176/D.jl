# %% constants & libraries
# ------------------------

# %% body
# -------

@inbounds function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))::Vector{T}

    # handle IO and and stuff
    H::Int, W::Int = readnum()
    Ch::Int, Cw::Int = readnum()
    Dh::Int, Dw::Int = readnum()
    S::Matrix{Char} = Matrix{Char}(undef, H, W)
    for h in 1:H
        S[h, :] = collect(readto())
    end

    dp::Matrix{Int} = ones(Int, (H, W)) .* -1

    function walk!(h, w, cost)
        if S[h, w] === '#'
            return
        end
        dp[h, w] !== -1 && dp[h, w] ≤ cost && return
        dp[h, w] = cost

        h > 1 && walk!(h - 1, w, cost)
        h < H && walk!(h + 1, w, cost)
        w > 1 && walk!(h, w - 1, cost)
        w < W && walk!(h, w + 1, cost)

        h > 1 && w > 1 && walk!(h - 1, w - 1, cost + 1)
        h > 1 && w < W && walk!(h - 1, w + 1, cost + 1)
        h < H && w > 1 && walk!(h + 1, w - 1, cost + 1)
        h < H && w < W && walk!(h + 1, w + 1, cost + 1)

        h > 2 && w > 2 && walk!(h - 2, w - 2, cost + 1)
        h > 2 && w > 1 && walk!(h - 2, w - 1, cost + 1)
        h > 2 && walk!(h - 2, w, cost + 1)
        h > 2 && w < W && walk!(h - 2, w + 1, cost + 1)
        h > 2 && w < W - 1 && walk!(h - 2, w + 2, cost + 1)

        h > 1 && w > 2 && walk!(h - 1, w - 2, cost + 1)
        h > 1 && w < W - 1 && walk!(h - 1, w + 2, cost + 1)

        w > 2 && walk!(h, w - 2, cost + 1)
        w < W - 1 && walk!(h, w + 2, cost + 1)

        h < H && w > 2 && walk!(h + 1, w - 2, cost + 1)
        h < H && w < W - 1 && walk!(h + 1, w + 2, cost + 1)

        h < H - 1 && w > 2 && walk!(h + 2, w - 2, cost + 1)
        h < H - 1 && w > 1 && walk!(h + 2, w - 1, cost + 1)
        h < H - 1 && walk!(h + 2, w, cost + 1)
        h < H - 1 && w < W && walk!(h + 2, w + 1, cost + 1)
        h < H - 1 && w < W - 1 && walk!(h + 2, w + 2, cost + 1)
    end

    walk!(Ch, Cw, 0)

    println(dp[Dh, Dw])
end

@static if @isdefined(Juno) || @isdefined(VSCodeServer)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
