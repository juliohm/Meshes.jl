# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Segment(p1, p2)

An oriented line segment with end points `p1`, `p2`.
The segment can be called as `s(t)` with `t` between
`0` and `1` to interpolate linearly between its endpoints.

See also [`Rope`](@ref), [`Ring`](@ref), [`Line`](@ref).
"""
@polytope Segment 1 2

nvertices(::Type{<:Segment}) = 2

Base.minimum(s::Segment) = s.vertices[1]

Base.maximum(s::Segment) = s.vertices[2]

Base.extrema(s::Segment) = s.vertices[1], s.vertices[2]

center(s::Segment) = s(0.5)

Base.isapprox(s₁::Segment, s₂::Segment; kwargs...) =
  all(isapprox(v₁, v₂; kwargs...) for (v₁, v₂) in zip(s₁.vertices, s₂.vertices))

function (s::Segment{Dim,T})(t) where {Dim,T}
  TT = get_precision(s)
  t = TT(t)
  if t < zero(TT) || t > one(TT)
    throw(DomainError(t, "s(t) is not defined for t outside [0, 1]."))
  end
  a, b = s.vertices
  a + t * (b - a)
end
