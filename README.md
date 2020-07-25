my footprints on [atcoder](https://atcoder.jp/home?lang=en)

TODO: automatic problem setup & sample download, maybe


## workflow

1. fire up [Juno](https://junolab.org/)
2. copy [tmpl.jl](./tmpl.jl) and paste and save it into a file (let to be `prob.jl`)
3. create a sample input file and name it `prob.in`
4. run `prob.jl` interactively and solve !

> [tmpl.jl](./tmpl.jl)

```julia
# %% constants
# ------------

# %% body
# -------

function main(io = stdin)
    readto(target = '\n') = readuntil(io, target)
    readnum(T::Type{<:Number} = Int; dlm = isspace, kwargs...) =
        parse.(T, split(readto(), dlm; kwargs...))

    # handle IO and and stuff
end

function solve()
    # ...
end

@static if @isdefined(Juno)
    main(open(replace(@__FILE__, r"(.+)\.jl" => s"\1.in")))
else
    main()
end
```
