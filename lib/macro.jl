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


# %% comparison example

function forbench(n)
    ret = 0
    for i in 1:n-1
        ret = max(ret, gcd(i,n))
    end
    return ret
end
function genbench(n)
    return @generator for i in 1:n-1
        gcd(i,n)
    end |> maximum
end

using BenchmarkTools
forbench(10)
genbench(10)
n = 1000000
# should be almost same performance
@btime forbench($n)
@btime genbench($n)
