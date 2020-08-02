# %% constants or libraries
# -------------------------

# adapted:
# - from https://github.com/JuliaLang/julia/blob/805b6597e05256059a5d412d615a6486406f74c0/base/sort.jl
# - by @aviatesk, 2020/03/26
#
# NOTE:
# This file extends `searchsorted`, `searchsortedfirst` and `searchsortedlast` so that
# they can accept a "converter" function as their first argument

import Base.Sort: searchsorted, searchsortedfirst, searchsortedlast

using Base.Order
@static if VERSION < v"1.4"
    # This implementation of `midpoint` is performance-optimized but safe
    # only if `lo <= hi`.
    midpoint(lo::T, hi::T) where T<:Integer = lo + ((hi - lo) >>> 0x01)
    midpoint(lo::Integer, hi::Integer) = midpoint(promote(lo, hi)...)
else
    import Base.Sort: midpoint
end

for s in [:searchsortedfirst, :searchsortedlast, :searchsorted]
    @eval begin
        $s(f, v::AbstractVector, x, o::Ordering) = (inds = axes(v, 1); $s(f, v,x,first(inds),last(inds),o))
        $s(f, v::AbstractVector, x;
           lt=isless, by=identity, rev::Union{Bool,Nothing}=nothing, order::Ordering=Forward) =
            $s(f,v,x,ord(lt,by,rev,order))
    end
end

function searchsortedfirst(f, v::AbstractVector, x, lo::T, hi::T, o::Ordering) where T<:Integer
    u = T(1)
    lo = lo - u
    hi = hi + u
    @inbounds while lo < hi - u
        m = midpoint(lo, hi)
        if lt(o, f(v[m]), x)
            lo = m
        else
            hi = m
        end
    end
    return hi
end

function searchsortedlast(f, v::AbstractVector, x, lo::T, hi::T, o::Ordering) where T<:Integer
    u = T(1)
    lo = lo - u
    hi = hi + u
    @inbounds while lo < hi - u
        m = midpoint(lo, hi)
        if lt(o, x, f(v[m]))
            hi = m
        else
            lo = m
        end
    end
    return lo
end

function searchsorted(f, v::AbstractVector, x, ilo::T, ihi::T, o::Ordering) where T<:Integer
    u = T(1)
    lo = ilo - u
    hi = ihi + u
    @inbounds while lo < hi - u
        m = midpoint(lo, hi)
        y = f(v[m])
        if lt(o, y, x)
            lo = m
        elseif lt(o, x, y)
            hi = m
        else
            a = searchsortedfirst(f, v, x, max(lo,ilo), m, o)
            b = searchsortedlast(f, v, x, m, min(hi,ihi), o)
            return a : b
        end
    end
    return (lo + 1) : (hi - 1)
end


# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and and stuff
    N, K = readnum()
    A = readnum()
    println(solve(N, K, A))
end

function solve(N, K, A)
    return searchsortedfirst(1:maximum(A), K; rev = true) do target
        return sum(ceil.(Int, A ./ (target)) .- 1)
    end
end

@static if @isdefined(Juno) || @isdefined(VSCodeServer)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
