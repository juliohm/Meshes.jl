# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    ∠(A, B, C)

Angle ∠ABC between rays BA and BC.
See https://en.wikipedia.org/wiki/Angle.

## Example

```julia
∠(Point(0,1), Point(0,0), Point(1,0)) == π/2
```
"""
function ∠(A::P, B::P, C::P) where {P<:Point{2}}
  BA = A - B
  BC = C - B

  cross = BA × BC
  inner = BA ⋅ BC

  atan(cross, inner)
end
