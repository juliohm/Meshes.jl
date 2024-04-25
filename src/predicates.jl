# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

# unary predicates
include("predicates/isparametrized.jl")
include("predicates/isperiodic.jl")
include("predicates/issimplex.jl")
include("predicates/isclosed.jl")
include("predicates/isconvex.jl")
include("predicates/issimple.jl")
include("predicates/hasholes.jl")

# binary predicates
# TODO: use coordtype
# include("predicates/in.jl")
include("predicates/issubset.jl")
# TODO: use coordtype
# include("predicates/intersects.jl")

# other predicates
include("predicates/iscollinear.jl")
include("predicates/iscoplanar.jl")
