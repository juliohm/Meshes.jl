# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Line(a, b)

A line passing through points `a` and `b`.

See also [`Segment`](@ref).
"""
struct Line{Dim,C<:CRS} <: Primitive{Dim,C}
  a::Point{Dim,C}
  b::Point{Dim,C}
end

Line(a::Tuple, b::Tuple) = Line(Point(a), Point(b))

paramdim(::Type{<:Line}) = 1

==(l₁::Line, l₂::Line) = l₁.a ∈ l₂ && l₁.b ∈ l₂ && l₂.a ∈ l₁ && l₂.b ∈ l₁

Base.isapprox(l₁::Line, l₂::Line) = l₁.a ≈ l₂.a && l₁.b ≈ l₂.b

(l::Line)(t) = l.a + t * (l.b - l.a)

Random.rand(rng::Random.AbstractRNG, ::Type{Line{Dim}}) where {Dim} = Line(rand(rng, Point{Dim}), rand(rng, Point{Dim}))
