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
    bruteforcesearch(n::Integer, b::Integer = 2)
    bruteforcesearch(f::Function, n::Integer, b::Integer = 2)

$(""#=TODO: add some equation here for the future reference=#)

!!! note
    By default (i.e. when `b == 2`), this function is equivalent to bit-brute-force search.

```julia-repl
julia> for gen in bruteforcesearch(3)
           @show collect(gen)
       end
collect(gen) = [2, 1, 1]
collect(gen) = [1, 2, 1]
collect(gen) = [2, 2, 1]
collect(gen) = [1, 1, 2]
collect(gen) = [2, 1, 2]
collect(gen) = [1, 2, 2]
collect(gen) = [2, 2, 2]
collect(gen) = [1, 1, 1]

julia> bruteforcesearch(2, 3) do gen
           @show collect(gen)
       end |> collect;
collect(gen) = [2, 1]
collect(gen) = [3, 1]
collect(gen) = [1, 2]
collect(gen) = [2, 2]
collect(gen) = [3, 2]
collect(gen) = [1, 3]
collect(gen) = [2, 3]
collect(gen) = [3, 3]
collect(gen) = [1, 1]
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

@inbounds begin

function bruteforcesearch(n::Integer, b::Integer = 2)
    baselen = length(string(b, base = 10))
    return @generator for i = 1:b^n
        s = reverse(string(i, pad = n, base = b))[1:n] # cut off the overflowed char when `i == base^n`
        @generator for ns in partition(s, baselen)
            parse(Int, ns) + 1 # for 1-based indexing
        end
    end
end

function bruteforcesearch(f::Function, n::Integer, b::Integer = 2)
    baselen = length(string(b, base = 10))
    return @generator for i = 1:b^n
        s = reverse(string(i, pad = n, base = b))[1:n] # cut off the overflowed char when `i == base^n`
        gen = @generator for ns in partition(s, baselen)
            parse(Int, ns) + 1 # for 1-based indexing
        end
        f(gen)
    end
end

function partition(a, n)
    return if n == 1
        a
    else
        @collect for i in 1:(length(a)÷n)
            s = 1+n*(i-1)
            e = n*i
            a[s:e]
        end
    end
end

end # @inbounds

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

@inbounds function solve(N, XYPs)
    # TODO: precomputation
    Xcaches = [Dict{UInt,Int}() for _ in 1:N]
    Ycaches = [Dict{UInt,Int}() for _ in 1:N]

    for roads in bruteforcesearch(N, 2)
        Xs = Set(X for (road, (X, _)) in zip(roads, XYPs) if road == 1)
        Ys = Set(Y for (road, (_, Y, _)) in zip(roads, XYPs) if road == 1)
        push!(Xs, 0); push!(Ys, 0)
        cache_distances!(XYPs, Xs, Ys, Xcaches, Ycaches)
    end

    ret = [typemax(Int) for n in 0:N]

    # calculate shortest distances for all the candidates
    for roads in bruteforcesearch(N, 3)
        Xs = Set(0)
        Ys = Set(0)
        cnt = @generator for (road, (X, Y, _)) in zip(roads, XYPs)
            if road == 1
                push!(Xs, X)
                1
            elseif road == 2
                push!(Ys, Y)
                1
            else # no road here, no count
                0
            end
        end |> sum
        ret[cnt + 1] = min(ret[cnt + 1], sumup_distances(XYPs, Xs, Ys, Xcaches, Ycaches))
    end

    return ret
end

function cache_distances!(XYPs, Xs, Ys, Xcaches, Ycaches)
    for ((X, Y, _), Xcache, Ycache) in zip(XYPs, Xcaches, Ycaches)
        cache_distance!(Xcache, X, Xs)
        cache_distance!(Ycache, Y, Ys)
    end
end

function cache_distance!(cache, p, ps)
    k = hash(ps)
    haskey(cache, k) && return
    cache[k] = shortest_distance(p, ps)
end

shortest_distance(p, ps) = minimum(abs(p - x) for x in ps)

@inbounds function sumup_distances(XYPs, Xs, Ys, Xcaches, Ycaches)
    xk = hash(Xs)
    yk = hash(Ys)
    return @generator for ((_, _, P), Xcache, Ycache) in zip(XYPs, Xcaches, Ycaches)
        min(Xcache[xk], Ycache[yk]) * P
    end |> sum
end

@static if @isdefined(Juno)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
