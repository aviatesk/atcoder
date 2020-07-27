# adapted:
# - from https://github.com/JuliaCollections/DataStructures.jl/blob/685d33d4863e66c6e4d2b4b8eda1c2cce823d41e/src/disjoint_set.jl
# - by @aviatesk, 2019/12/17

# Disjoint sets

############################################################
#
#   A forest of disjoint sets of integers
#
#   Since each element is an integer, we can use arrays
#   instead of dictionary (for efficiency)
#
#   Disjoint sets over other key types can be implemented
#   based on an DisjointSets through a map from the key
#   to an integer index
#
############################################################

mutable struct DisjointSets
    parents::Vector{Int}
    ranks::Vector{Int}
    ngroups::Int

    # creates a disjoint set comprised of n singletons
    DisjointSets(n::Integer) = new(collect(1:n), zeros(Int, n), n)
end

Base.length(s::DisjointSets) = length(s.parents)
num_groups(s::DisjointSets) = s.ngroups
Base.eltype(::Type{DisjointSets}) = Int

# find the root element of the subset that contains x
# path compression is implemented here

function find_root_impl!(parents::Array{Int}, x::Integer)
    p = parents[x]
    @inbounds if parents[p] != p
        parents[x] = p = _find_root_impl!(parents, p)
    end
    p
end

# unsafe version of the above
function _find_root_impl!(parents::Array{Int}, x::Integer)
    @inbounds p = parents[x]
    @inbounds if parents[p] != p
        parents[x] = p = _find_root_impl!(parents, p)
    end
    p
end

find_root(s::DisjointSets, x::Integer) = find_root_impl!(s.parents, x)

"""
    is_in_same_set(s::DisjointSets, x::Integer, y::Integer)

Returns `true` if `x` and `y` belong to the same subset in `s` and `false` otherwise.
"""
is_in_same_set(s::DisjointSets, x::Integer, y::Integer) = find_root(s, x) == find_root(s, y)

# merge the subset containing x and that containing y into one
# and return the root of the new set.
function union!(s::DisjointSets, x::Integer, y::Integer)
    parents = s.parents
    xroot = find_root_impl!(parents, x)
    yroot = find_root_impl!(parents, y)
    xroot != yroot ?  root_union!(s, xroot, yroot) : xroot
end

# form a new set that is the union of the two sets whose root elements are
# x and y and return the root of the new set
# assume x ≠ y (unsafe)
function root_union!(s::DisjointSets, x::Integer, y::Integer)
    parents = s.parents
    rks = s.ranks
    @inbounds xrank = rks[x]
    @inbounds yrank = rks[y]

    if xrank < yrank
        x, y = y, x
    elseif xrank == yrank
        rks[x] += 1
    end
    @inbounds parents[y] = x
    @inbounds s.ngroups -= 1
    x
end

# make a new subset with an automatically chosen new element x
# returns the new element
#
function Base.push!(s::DisjointSets)
    x = length(s) + 1
    push!(s.parents, x)
    push!(s.ranks, 0)
    s.ngroups += 1
    return x
end
