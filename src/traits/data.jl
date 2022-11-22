# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Data

A domain implementing the [`Domain`](@ref) trait together with tables
of values for geometries of the domain.

See also [`meshdata`](@ref).
"""
abstract type Data end

"""
    domain(data)

Return underlying domain of the `data`.
"""
function domain end

"""
    values(data, [rank])

Return the values of `data` for a given `rank` as a table.

The rank is a non-negative integer that specifies the
parametric dimension of the geometries of interest:

* 0 - points
* 1 - segments
* 2 - triangles, quadrangles, ...
* 3 - tetrahedrons, hexahedrons, ...

If the rank is not specified, it is assumed to be the rank
of the elements of the domain.
"""
function values end

"""
    constructor(D)

Return the constructor of the data type `D` as a function.
The function takes a domain and a dictionary of tables as
inputs and combines them into an instance of the data type.
"""
function constructor end

# ----------
# FALLBACKS
# ----------

constructor(::D) where {D<:Data} = constructor(D)

function (D::Type{<:Data})(geotable)
  # build domain from geometry column
  cols   = Tables.columns(geotable)
  elms   = Tables.getcolumn(cols, :geometry)
  domain = Collection(elms)

  # build table of features from remaining columns
  vars  = setdiff(Tables.columnnames(cols), (:geometry,))
  ncols = [var => Tables.getcolumn(cols, var) for var in vars]
  table = (; ncols...)

  # data table for elements
  values = Dict(paramdim(domain) => table)

  # combine the two with constructor
  constructor(D)(domain, values)
end

function ==(data₁::Data, data₂::Data)
  # must have the same domain
  if domain(data₁) != domain(data₂)
    return false
  end

  # must have the same data tables
  for rank in 0:paramdim(domain(data₁))
    vals₁ = values(data₁, rank)
    vals₂ = values(data₂, rank)
    if !isequal(vals₁, vals₂)
      return false
    end
  end

  return true
end

nitems(data::Data) = nelements(domain(data))

# -----------------
# TABLES INTERFACE
# -----------------

Tables.istable(::Type{<:Data}) = true

Tables.rowaccess(::Type{<:Data}) = true

Tables.rows(data::Data) = DataRows(domain(data), Tables.rows(values(data)))

Tables.schema(data::Data) = Tables.schema(Tables.rows(data))

# wrapper type for rows of the data table
# so that we can easily inform the schema
struct DataRows{𝒟,ℛ}
  domain::𝒟
  trows::ℛ
end

Base.length(rows::DataRows) = nelements(rows.domain)

function Base.iterate(rows::DataRows, state=1)
  if state > length(rows)
    nothing
  else
    row, _ = iterate(rows.trows, state)
    elm, _ = iterate(rows.domain, state)
    names  = Tables.columnnames(row)
    pairs  = (nm => Tables.getcolumn(row, nm) for nm in names)
    (; pairs..., geometry=elm), state + 1
  end
end

function Tables.schema(rows::DataRows)
  geomtype = eltype(rows.domain)
  schema = Tables.schema(rows.trows)
  names, types = schema.names, schema.types
  Tables.Schema((names..., :geometry), (types..., geomtype))
end

Tables.materializer(D::Type{<:Data}) = D

# --------------------
# DATAFRAME INTERFACE
# --------------------

function Base.getproperty(data::Data, var::Symbol)
  if var == :geometry
    domain(data)
  else
    cols = Tables.columns(values(data))
    Tables.getcolumn(cols, var)
  end
end

Base.getproperty(data::Data, var::AbstractString) =
  getproperty(data, Symbol(var))

function Base.getindex(data::Data,
                       inds::AbstractVector{Int},
                       vars::AbstractVector{Symbol})
  _checkvars(vars)
  _rmgeometry!(vars)
  dom    = domain(data)
  tab    = values(data)
  newdom = view(dom, inds)
  subset = Tables.subset(tab, inds)
  cols   = Tables.columns(subset)
  pairs  = (var => Tables.getcolumn(cols, var) for var in vars)
  newtab = (; pairs...) |> Tables.materializer(tab)

  newvals = Dict(paramdim(newdom) => newtab)
  constructor(data)(newdom, newvals)
end

Base.getindex(data::Data,
              inds::AbstractVector{Int},
              vars::AbstractVector{<:AbstractString}) =
  getindex(data, inds, Symbol.(vars))

Base.getindex(data::Data,
              inds::AbstractVector{Int},
              var::Symbol) =
  getproperty(view(data, inds), var)

function Base.getindex(data::Data,
                       inds::AbstractVector{Int},
                       ::Colon)
  dview = view(data, inds)
  constructor(data)(domain(dview), values(dview))
end

Base.getindex(data::Data,
              inds::AbstractVector{Int},
              var::AbstractString) =
  getindex(data, inds, Symbol(var))

function Base.getindex(data::Data,
                       ind::Int,
                       vars::AbstractVector{Symbol})
  _checkvars(vars)
  _rmgeometry!(vars)
  dom   = domain(data)
  tab   = values(data)
  row   = Tables.subset(tab, ind)
  pairs = (var => Tables.getcolumn(row, var) for var in vars)
  (; pairs..., geometry=dom[ind])
end

Base.getindex(data::Data,
              ind::Int,
              vars::AbstractVector{<:AbstractString}) =
  getindex(data, ind, Symbol.(vars))

Base.getindex(data::Data, ind::Int, var::Symbol) =
  getproperty(data, var)[ind]

Base.getindex(data::Data, ind::Int, var::AbstractString) =
  getindex(data, ind, Symbol(var))

function Base.getindex(data::Data, ind::Int, ::Colon)
  dom   = domain(data)
  tab   = values(data)
  row   = Tables.subset(tab, ind)
  vars  = Tables.columnnames(row)
  pairs = (var => Tables.getcolumn(row, var) for var in vars)
  (; pairs..., geometry=dom[ind])
end

function Base.getindex(data::Data,::Colon, vars::AbstractVector{Symbol})
  _checkvars(vars)
  _rmgeometry!(vars)
  dom    = domain(data)
  tab    = values(data)
  cols   = Tables.columns(tab)
  pairs  = (var => Tables.getcolumn(cols, var) for var in vars)
  newtab = (; pairs...) |> Tables.materializer(tab)

  newvals = Dict(paramdim(dom) => newtab)
  constructor(data)(dom, newvals)
end

Base.getindex(data::Data, ::Colon, vars::AbstractVector{<:AbstractString}) =
  getindex(data, :, Symbol.(vars))

Base.getindex(data::Data, ::Colon, var::Symbol) =
  getproperty(data, var)

Base.getindex(data::Data, ::Colon, var::AbstractString) =
  getproperty(data, Symbol(var))

# utils
function _checkvars(vars)
  if !allunique(vars)
    throw(ArgumentError("The variable names must be unique"))
  end
end

function _rmgeometry!(vars)
  ind = findfirst(==(:geometry), vars)
  if !isnothing(ind)
    popat!(vars, ind)
  end
end

# -------------------
# VARIABLE INTERFACE
# -------------------

"""
    variables(data)

Returns the variables stored in `data` as a vector of
[`Variable`](@ref).
"""
function variables(data::Data)
  s = Tables.schema(values(data))
  @. Variable(s.names, nonmissingtype(s.types))
end

"""
    asarray(data, var)

Returns the data for the variable `var` in `data` as a Julia array
with size equal to the size of the underlying domain if the size is
defined, otherwise returns a vector.
"""
function asarray(data::Data, var::Symbol)
  D = domain(data)
  hassize = hasmethod(size, (typeof(D),))
  dataval = getproperty(data, var)
  hassize ? reshape(dataval, size(D)) : dataval
end

asarray(data::Data, var::AbstractString) =
  asarray(data, Symbol(var))

# -----------
# IO METHODS
# -----------

function Base.show(io::IO, data::Data)
  name = nameof(typeof(data))
  nelm = nelements(domain(data))
  print(io, "$nelm $name")
end

function Base.show(io::IO, ::MIME"text/plain", data::Data)
  l = []
  𝒟 = domain(data)
  for rank in 0:paramdim(𝒟)
    𝒯 = values(data, rank)
    if !isnothing(𝒯)
      sche = Tables.schema(𝒯)
      vars = zip(sche.names, sche.types)
      push!(l, "  variables (rank $rank)")
      append!(l, ["    └─$var ($V)" for (var,V) in vars])
    end
  end
  println(io, 𝒟)
  print(io, join(l, "\n"))
end
