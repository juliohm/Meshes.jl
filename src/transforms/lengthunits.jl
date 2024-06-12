# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    LengthUnit(unit)

Convert the length unit of coordinates of a geometry or domain to `unit`.

## Examples

```julia
LengthUnit(u"cm")
LengthUnit(u"km")
```
"""
struct LengthUnit{U} <: CoordinateTransform
  unit::U
end

parameters(t::LengthUnit) = (; unit=t.unit)

applycoord(t::LengthUnit, v::Vec) = uconvert.(t.unit, v)

function applycoord(t::LengthUnit, p::Point{<:Any,<:Cartesian})
  c = CoordRefSystems.cvalues(coords(p))
  Point(Cartesian{datum(crs(p))}(uconvert.(t.unit, c)))
end

function applycoord(t::LengthUnit, p::Point{<:Any,<:Polar})
  c = coords(p)
  ρ = uconvert(t.unit, c.ρ)
  Point(Polar{datum(crs(p))}(ρ, c.ϕ))
end

function applycoord(t::LengthUnit, p::Point{<:Any,<:Cylindrical})
  c = coords(p)
  ρ = uconvert(t.unit, c.ρ)
  z = uconvert(t.unit, c.z)
  Point(Cylindrical{datum(crs(p))}(ρ, c.ϕ, z))
end

function applycoord(t::LengthUnit, p::Point{<:Any,<:Spherical})
  c = coords(p)
  r = uconvert(t.unit, c.r)
  Point(Spherical{datum(crs(p))}(r, c.θ, c.ϕ))
end

applycoord(::LengthUnit, p::Point) = throw(ArgumentError("the length unit of $(prettyname(crs(p))) cannot be changed"))

# --------------
# SPECIAL CASES
# --------------

applycoord(t::LengthUnit, g::RectilinearGrid) = RectilinearGrid{datum(crs(g))}(map(x -> uconvert.(t.unit, x), xyz(g)))

applycoord(t::LengthUnit, g::StructuredGrid) = StructuredGrid{datum(crs(g))}(map(X -> uconvert.(t.unit, X), XYZ(g)))
