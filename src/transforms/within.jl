# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Within(x=(xmin, xmax), y=(ymin, ymax), z=(zmin, zmax))

Retain the domain geometries that are within `x` limits [`xmax`,`xmax`],
`y` limits [`ymax`,`ymax`] and `z` limits [`zmin`,`zmax`] in length units
(default to meters).

## Examples

```julia
Within(x=(2, 4))
Within(x=(1u"km", 3u"km"))
Within(y=(1.2, 1.8), z=(2.4, 3.0))
```
"""
struct Within{X,Y,Z} <: GeometricTransform
  x::X
  y::Y
  z::Z
end

Within(; x=nothing, y=nothing, z=nothing) =
  Within(isnothing(x) ? x : _aslen.(x), isnothing(y) ? y : _aslen.(y), isnothing(z) ? z : _aslen.(z))

parameters(t::Within) = (; x=t.x, y=t.y, z=t.z)

function preprocess(t::Within, d::Domain)
  bbox = boundingbox(d)
  bbox₁ = _within(1, t.x, bbox)
  bbox₂ = _within(2, t.y, bbox₁)
  bbox₃ = _within(3, t.z, bbox₂)
  indices(d, bbox₃)
end

function apply(t::Within, d::Domain)
  inds = preprocess(t, d)
  n = view(d, inds)
  n, nothing
end

_aslen(x::Len) = float(x)
_aslen(x::Number) = float(x) * u"m"
_aslen(x::Quantity) = throw(ArgumentError("invalid units, please check the documentation"))

function _within(dim, bound, bbox)
  Dim = embeddim(bbox)
  if Dim < dim || isnothing(bound)
    bbox
  else
    bmin, bmax = bound
    min = to(minimum(bbox))
    max = to(maximum(bbox))
    nmin = Vec(ntuple(i -> i == dim ? bmin : min[i], Dim))
    nmax = Vec(ntuple(i -> i == dim ? bmax : max[i], Dim))
    Box(withdatum(bbox, nmin), withdatum(bbox, nmax))
  end
end
