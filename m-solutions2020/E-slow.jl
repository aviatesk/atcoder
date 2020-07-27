# %% library
# ----------

# %% library docs
# ---------------

"""
    @collect [cond] ex

Constructs [`Array`](@ref) from lastly evaluated values from a `for` loop block that appears
  first within given `ex` expression.
If the optional `cond` expression is given, iterations  where the `cond` is `false` are
  effectively filtered out.

```julia-repl
julia> @collect isodd(i) for i = 1:3
           println("i = ", i); i
       end
i = 1
i = 3
2-element Array{Int64,1}:
 1
 3
```

See also: [`@generator`](@ref)
"""
macro collect end

"""
    @generator [cond] ex

Constructs [`Base.Generator`](@ref) from lastly evaluated values from a `for` loop block
  that appears first within given `ex` expression.
If the optional `cond` expression is given, iterations where the `cond` is `false` are
  effectively filtered out.

```julia-repl
julia> @generator isodd(i) for i = 1:3
           println("i = ", i); i
       end |> sum
i = 1
i = 3
4
```

See also: [`@collect`](@ref)
"""
macro generator end

"""
    bruteforcesearch(f::Function, n::Integer, b::Integer = 2)

Applies `f` for all the ...
$(""#=TODO: add some equation here for the future reference=#)

!!! note
    By default (i.e. when `b == 2`), this function is equivalent to bit-brute-force search.

```julia-repl
julia> bruteforcesearch(3) do comb
           @show collect(comb)
       end;
collect(mask) = [2, 1, 1]
collect(mask) = [1, 2, 1]
collect(mask) = [2, 2, 1]
collect(mask) = [1, 1, 2]
collect(mask) = [2, 1, 2]
collect(mask) = [1, 2, 2]
collect(mask) = [2, 2, 2]
collect(mask) = [1, 1, 1]

julia> bruteforcesearch(2, 3) do comb
           @show collect(comb)
       end;
collect(mask) = [2, 1]
collect(mask) = [3, 1]
collect(mask) = [1, 2]
collect(mask) = [2, 2]
collect(mask) = [3, 2]
collect(mask) = [1, 3]
collect(mask) = [2, 3]
collect(mask) = [3, 3]
collect(mask) = [1, 1]
```
"""
function bruteforcesearch end

# %% library body
# ---------------

function decompose_forblk(forblk)
    @assert Meta.isexpr(forblk, :for) "for block expression should be given"
    itrspec, body = forblk.args
    @assert Meta.isexpr(itrspec, :(=)) "invalid for loop specification"
    v, itr = itrspec.args
    return body, v, itr
end

function recompose_to_comprehension(forblk, cond = nothing; gen = false)
    body, v, itr = decompose_forblk(forblk)
    return isnothing(cond) ?
        esc(gen ? :(($body for $v in $itr)) : :([$body for $v in $itr])) :
        esc(gen ? :(($body for $v in $itr if $cond)) : :([$body for $v in $itr if $cond]))
end

function walk_and_transform(x, cond = nothing; gen = false)
    Meta.isexpr(x, :for) && return recompose_to_comprehension(x, cond; gen = gen), true
    x isa Expr || return x, false
    for (i, ex) in enumerate(x.args)
        ex, transformed = walk_and_transform(ex, cond; gen = gen)
        x.args[i] = ex
        transformed && return x, true # already transformed
    end
    return x, false
end

macro collect(ex) first(walk_and_transform(ex)) end
macro collect(cond, ex) first(walk_and_transform(ex, cond)) end

macro generator(ex) first(walk_and_transform(ex; gen = true)) end
macro generator(cond, ex) first(walk_and_transform(ex, cond; gen = true)) end

@inbounds function bruteforcesearch(f::Function, n::Integer, b::Integer = 2)
    baselen = length(string(b, base = 10))
    @collect for i = 1:b^n
        s = reverse(string(i, pad = n, base = b))[1:n] # cut off the overflowed char when `i == base^n`
        comb = @generator for ns in partition(s, baselen)
            parse(Int, ns) + 1 # for 1-based indexing
        end
        f(comb)
    end
end

partition(a, n) = @generator for i in 1:(length(a)÷n)
    s = 1+n*(i-1)
    e = n*i
    a[s:e]
end

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
    XYPs = [readnum() for _ in 1:N]
    println.(solve(N, XYPs))
end

function solve(N, XYPs)
    # TODO: precomputation
    ret = [typemax(Int) for n in 0:N]

    # calculate shortest distances for all the candidates
    bruteforcesearch(N, 3) do roads
        Ys = [0]
        Xs = [0]
        cnt = @collect for (road, (X, Y, _)) in zip(roads, XYPs)
            if road == 1
                push!(Xs, X)
                1
            elseif road == 2
                push!(Ys, Y)
                1
            else road == 3
                0 # no road here, no count
            end
        end |> sum
        ret[cnt + 1] = min(ret[cnt + 1], sumup_distances(XYPs, Xs, Ys))
    end

    return ret
end

sumup_distances(XYPs, Xs, Ys) = @generator for (X, Y, P) in XYPs
    shortest_distance(X, Y, Xs, Ys) * P
end |> sum

function shortest_distance(X, Y, Xs, Ys)
    xdist = minimum(abs(x - X) for x in Xs)
    ydist = minimum(abs(y - Y) for y in Ys)
    return min(xdist, ydist)
end

@static if @isdefined(Juno)
    main(open(normpath(@__DIR__, "E.in")))
else
    main()
end
