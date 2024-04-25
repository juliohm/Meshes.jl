# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    ParaboloidSurface(apex, radius, focallength)

A paraboloid surface embedded in R³ and extending up to a distance
`radius` from its focal axis, which is aligned along the z direction
and passes through `apex` (the apex of the paraboloid). The equation
of the paraboloid is the following:

```math
f(x, y) = \\frac{(x - x_0)^2 + (y - y_0)^2}{4f} + z_0\\qquad\\text{for } x^2 + y^2 < r^2,
```

where ``(x_0, y_0, z_0)`` is the apex of the parabola, ``f`` is the
focal length, and ``r`` is the clip radius.

    ParaboloidSurface(apex, radius)

This creates a paraboloid surface with focal length equal to 1.

    ParaboloidSurface(apex)

This creates a paraboloid surface with focal length equal to 1 and a rim with unit
radius.

    ParaboloidSurface()

Same as above, but here the apex is at `Apex(0, 0, 0)`.

See also <https://en.wikipedia.org/wiki/Paraboloid>.
"""
struct ParaboloidSurface{P<:Point{3},ℒ<:Len} <: Primitive{3}
  apex::P
  radius::ℒ
  focallength::ℒ
  ParaboloidSurface(apex::P, radius::ℒ, focallength::ℒ) where {P<:Point{3},ℒ<:Len} =
    new{P,float(ℒ)}(apex, radius, focallength)
end

ParaboloidSurface(apex::Point{3}, radius::Len, focallength::Len) =
  ParaboloidSurface(apex, promote(radius, focallength)...)

ParaboloidSurface(apex::Point{3}, radius, focallength) =
  ParaboloidSurface(apex, addunit(radius, u"m"), addunit(focallength, u"m"))

ParaboloidSurface(apex::Tuple, radius, focallength) = ParaboloidSurface(Point(apex), radius, focallength)

ParaboloidSurface(apex::Point{3}, radius) = ParaboloidSurface(apex, radius, oneunit(radius))

ParaboloidSurface(apex::Tuple, radius) = ParaboloidSurface(Point(apex), radius)

ParaboloidSurface(apex::Point{3}) = ParaboloidSurface(apex, 1.0u"m")

ParaboloidSurface(apex::Tuple) = ParaboloidSurface(Point(apex))

ParaboloidSurface() = ParaboloidSurface(Point(0, 0, 0))

paramdim(::Type{<:ParaboloidSurface}) = 2

lentype(::Type{<:ParaboloidSurface{P}}) where {P} = lentype(P)

"""
    focallength(p::ParaboloidSurface)

Return the focal length of the paraboloid.
"""
focallength(p::ParaboloidSurface) = p.focallength

"""
    focallength(p::ParaboloidSurface)

Return the radius of the rim of the paraboloid.
"""
radius(p::ParaboloidSurface) = p.radius

"""
    apex(p::ParaboloidSurface)

Return the apex of the paraboloid.
"""
apex(p::ParaboloidSurface) = p.apex

"""
    axis(p::ParaboloidSurface)

Return the focal axis, connecting the focus with the apex of the paraboloid.
The axis is always aligned with the z direction.
"""
axis(p::ParaboloidSurface{P,ℒ}) where {P,ℒ} = Line(p.apex, p.apex + Vec(ℒ(0), ℒ(0), p.focallength))

Base.isapprox(p₁::ParaboloidSurface{P,ℒ}, p₂::ParaboloidSurface{P,ℒ}) where {P,ℒ} =
  p₁.apex ≈ p₂.apex &&
  isapprox(p₁.focallength, p₂.focallength, atol=atol(ℒ)) &&
  isapprox(p₁.radius, p₂.radius, atol=atol(ℒ))

function (p::ParaboloidSurface)(ρ, θ)
  T = numtype(lentype(p))
  if (ρ < 0 || ρ > 1)
    throw(DomainError((ρ, θ), "p(ρ, θ) is not defined for ρ outside [0, 1]."))
  end
  c = p.apex
  r = p.radius
  f = p.focallength
  l = T(ρ) * r
  sθ, cθ = sincospi(2 * T(θ))
  x = l * cθ
  y = l * sθ
  z = (x^2 + y^2) / 4f
  c + Vec(x, y, z)
end

# TODO
# Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{ParaboloidSurface{T}}) where {T} =
#   ParaboloidSurface(rand(rng, Point{3,T}), rand(rng, T), rand(rng, T))
