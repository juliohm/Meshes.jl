# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    CylinderSurface(bottom, top, radius)

A circular cylinder surface embedded in R³ with given `radius`,
delimited by `bottom` and `top` planes.

    CylinderSurface(start, finish, radius)

Alternatively, construct a right circular cylinder surface with given `radius`
along the segment with `start` and `finish` end points.

    CylinderSurface(start, finish)

Or construct a right circular cylinder surface with unit radius along the segment
with `start` and `finish` end points.

    CylinderSurface(radius)

Finally, construct a right vertical circular cylinder surface with given `radius`.

See <https://en.wikipedia.org/wiki/Cylinder>. 
"""
struct CylinderSurface{P<:Plane,ℒ<:Len} <: Primitive{3}
  bot::P
  top::P
  radius::ℒ
  CylinderSurface(bot::P, top::P, radius::ℒ) where {P<:Plane,ℒ<:Len} = new{P,float(ℒ)}(bot, top, radius)
end

CylinderSurface(bot::P, top::P, radius) where {P<:Plane} = CylinderSurface(bot, top, addunit(radius, u"m"))

function CylinderSurface(start::Point{3}, finish::Point{3}, radius)
  dir = finish - start
  bot = Plane(start, dir)
  top = Plane(finish, dir)
  CylinderSurface(bot, top, radius)
end

CylinderSurface(start::Tuple, finish::Tuple, radius) = CylinderSurface(Point(start), Point(finish), radius)

CylinderSurface(start::Point{3}, finish::Point{3}) = CylinderSurface(start, finish, 1.0u"m")

CylinderSurface(start::Tuple, finish::Tuple) = CylinderSurface(Point(start), Point(finish))

CylinderSurface(radius) = CylinderSurface(Point(0, 0, 0), Point(0, 0, 1), radius)

paramdim(::Type{<:CylinderSurface}) = 2

lentype(::Type{<:CylinderSurface{P}}) where {P} = lentype(P)

radius(c::CylinderSurface) = c.radius

bottom(c::CylinderSurface) = c.bot

top(c::CylinderSurface) = c.top

function center(c::CylinderSurface)
  a = coordinates(c.bot(0, 0))
  b = coordinates(c.top(0, 0))
  Point((a .+ b) ./ 2)
end

axis(c::CylinderSurface) = Line(c.bot(0, 0), c.top(0, 0))

function isright(c::CylinderSurface)
  ℒ = lentype(c)
  T = numtype(ℒ)
  # cylinder is right if axis
  # is aligned with plane normals
  a = axis(c)
  d = a(T(1)) - a(T(0))
  v = normal(c.bot)
  w = normal(c.top)
  nv = norm(d × v)
  nw = norm(d × w)
  isparallelv = isapprox(nv, zero(nv), atol=atol(nv))
  isparallelw = isapprox(nw, zero(nw), atol=atol(nw))
  isparallelv && isparallelw
end

Base.isapprox(c₁::CylinderSurface{P,ℒ}, c₂::CylinderSurface{P,ℒ}) where {P,ℒ} =
  c₁.bot ≈ c₂.bot && c₁.top ≈ c₂.top && isapprox(c₁.radius, c₂.radius, atol=atol(ℒ))

function (c::CylinderSurface)(φ, z)
  T = numtype(lentype(c))
  if (φ < 0 || φ > 1) || (z < 0 || z > 1)
    throw(DomainError((φ, z), "c(φ, z) is not defined for φ, z outside [0, 1]²."))
  end
  t = top(c)
  b = bottom(c)
  r = radius(c)
  a = axis(c)
  d = a(T(1)) - a(T(0))
  h = norm(d)
  o = center(c)

  # rotation to align z axis with cylinder axis
  Q = rotation_between(ustrip.(d), SVector(zero(T), zero(T), one(T)))

  # new normals of planes in new rotated system
  nᵦ = Q * normal(b)
  nₜ = Q * normal(t)

  # given cylindrical coordinates (r*cos(φ), r*sin(φ), z) and the
  # equation of the plane, we can solve for z and find all points
  # along the ellipse obtained by intersection
  rsφ, rcφ = r .* sincospi(2 * T(φ))
  zᵦ = -h / 2 - (rcφ * nᵦ[1] + rsφ * nᵦ[2]) / nᵦ[3]
  zₜ = +h / 2 - (rcφ * nₜ[1] + rsφ * nₜ[2]) / nₜ[3]
  pᵦ = Point(rcφ, rsφ, zᵦ)
  pₜ = Point(rcφ, rsφ, zₜ)

  p = pᵦ + T(z) * (pₜ - pᵦ)
  o + Q' * coordinates(p)
end

Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{CylinderSurface}) =
  CylinderSurface(rand(rng, Plane), rand(rng, Plane), rand(rng, Met{Float64}))

function hasintersectingplanes(c::CylinderSurface)
  x = c.bot ∩ c.top
  !isnothing(x) && evaluate(Euclidean(), axis(c), x) < c.radius
end
