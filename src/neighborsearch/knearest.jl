# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    KNearestSearch(domain, k; metric=Euclidean())

A method for searching `k` nearest neighbors in `domain`
according to `metric`.
"""
struct KNearestSearch{D,T} <: BoundedNeighborSearchMethod
  # input fields
  domain::D
  k::Int

  # state fields
  tree::T
end

function KNearestSearch(domain::D, k::Int; metric=Euclidean()) where {D}
  xs = [coordinates(centroid(domain, i)) for i in 1:nelements(domain)]
  tree = metric isa MinkowskiMetric ? KDTree(xs, metric) : BallTree(xs, metric)
  KNearestSearch{D,typeof(tree)}(domain, k, tree)
end

maxneighbors(method::KNearestSearch) = method.k

function search!(neighbors, pₒ::Point, method::KBallSearch; mask=nothing)
  distances = Vector{coordtype(pₒ)}(undef, maxneighbors(method))
  searchdists!(neighbors, distances, pₒ, method; mask)
end

function searchdists!(neighbors, distances, pₒ::Point, method::KBallSearch; mask=nothing)
  k = method.k
  inds, dists = knn(method.tree, coordinates(pₒ), k, true)

  if isnothing(mask)
    nneigh = k
    @inbounds for i in 1:k
      neighbors[i] = inds[i]
      distances[nneigh] = dists[i]
    end
  else
    nneigh = 0
    @inbounds for i in 1:k
      if mask[inds[i]]
        nneigh += 1
        neighbors[nneigh] = inds[i]
        distances[nneigh] = dists[i]
      end
    end
  end

  nneigh
end
