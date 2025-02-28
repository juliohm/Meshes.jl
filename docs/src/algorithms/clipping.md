# Clipping

```@example clipping
using Meshes # hide
import CairoMakie as Mke # hide
```

```@docs
clip
ClippingMethod
```

## Sutherland-Hodgman

```@docs
SutherlandHodgmanClipping
```

```@example clipping
# polygon to clip
outer = Ring((8, 0), (4, 8), (2, 8), (-2, 0), (0, 0), (1, 2), (5, 2), (6, 0))
inner = Ring((4, 4), (2, 4), (3, 6))
poly = PolyArea([outer, inner])

# clipping geometry
other = Box((0,1), (3,7))

# clipped polygon
clipped = clip(poly, other, SutherlandHodgmanClipping())

viz(poly)
viz!(other, color = :black, alpha = 0.2)
viz!(boundary(clipped), color = :red, segmentsize = 3)
Mke.current_figure()
```

## Weiler-Atherton

```@docs
WeilerAthertonClipping
```

```@example clipping
# polygon to clip
outer = Ring((8, 0), (4, 8), (2, 8), (-2, 0), (0, 0), (1, 2), (5, 2), (6, 0))
inner = Ring((4, 4), (2, 4), (3, 6))
poly = PolyArea([outer, inner])

# clipping geometry
other = outer |> Rotate(π) |> Translate(8, 8)

# clipped polygon
clipped = clip(poly, other, WeilerAthertonClipping())

viz(poly)
viz!(other, color = :black, alpha = 0.2)
viz!(boundary(clipped), color = :red, segmentsize = 3)
Mke.current_figure()
```