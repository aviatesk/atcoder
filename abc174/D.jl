# %% constants
# ------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and and stuff
    N, = readnum()
    c = readto()
    println(solve(N, c))
end

function solve(N, c)
    s = IOBuffer(c)
    rs = IOBuffer(reverse(c))

    wf = 1 + length(readuntil(s, 'W'))
    rl = N - length(readuntil(rs, 'R'))
    cnt = 0

    while rl > wf
        wf += 1 + length(readuntil(s, 'W'))
        rl -= 1 + length(readuntil(rs, 'R'))
        cnt += 1
    end

    return cnt
end

@static if @isdefined(Juno) || @isdefined(VSCodeServer)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
