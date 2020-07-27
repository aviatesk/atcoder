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
