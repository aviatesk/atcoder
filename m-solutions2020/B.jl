# %% constants
# ------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and stuff
    A, B, C = readnum()
    K, = readnum()
    println(solve(A, B, C, K) ? "Yes" : "No")
end

# A < B < C
function solve(A, B, C, K)
    for a in 0:K
        for b in 0:(K-a)
            for c in 0:(K-a-b)
                check(A, B, C, a, b, c) && return true
            end
        end
    end
    return false
end

check(A, B, C, a, b, c) = (2^a)*A < (2^b)*B < (2^c)*C

@static if @isdefined(Juno)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
