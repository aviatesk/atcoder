# %% constants
# ------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and stuff
    N, K = readnum()
    A = readnum()
    print_result.(solve(N, K, A))
end

print_result(r) = println(r ? "Yes" : "No")

@inbounds function solve(N, K, A)
    ret = zeros(Bool, N - K)
    for i in 1:(N-K)
        cur = A[i]
        next = A[K+i]
        ret[i] = next > cur
    end
    return ret
end

@static if @isdefined(Juno)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
