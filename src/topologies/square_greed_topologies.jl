
module SquareGreedTopologies

export SquareGreedIndex, SquareGreedTopology, SquareGreedIndexes, SquareGreedNeighborhood, manhattan_distance, ring_distance, euclidean_distance

using ...PCG.Types
using ...PCG.Geometry: Point
using ...PCG.Topologies
using ...PCG.Topologies: Topology, TopologyIndex, coordinates


const SquareGreedSize = Int64


struct SquareGreedIndex <: TopologyIndex
    x::SquareGreedSize
    y::SquareGreedSize
end


Base.zero(::Type{SquareGreedIndex}) = SquareGreedIndex(0, 0)
Base.zero(::SquareGreedIndex) = SquareGreedIndex(0, 0)


function Types.neighborsof(i::SquareGreedIndex)
    return [SquareGreedIndex(i.x+1, i.y+0),
            SquareGreedIndex(i.x+1, i.y+1),
            SquareGreedIndex(i.x+0, i.y+1),
            SquareGreedIndex(i.x-1, i.y+1),
            SquareGreedIndex(i.x-1, i.y+0),
            SquareGreedIndex(i.x-1, i.y-1),
            SquareGreedIndex(i.x-0, i.y-1),
            SquareGreedIndex(i.x+1, i.y-1)]
end


const SquareGreedIndexes = Vector{SquareGreedIndex}

# TODO: move somewere or remove
Point(cell::SquareGreedIndex) = Point(cell.x, cell.y)


Base.:+(a::Point, b::SquareGreedIndex) = Point(a.x + b.x,
                                               a.y + b.y)


Base.:+(a::SquareGreedIndex, b::SquareGreedIndex) = SquareGreedIndex(a.x + b.x,
                                                                     a.y + b.y)


struct SquareGreedTopology <: Topology
    width::SquareGreedSize
    height::SquareGreedSize
end


function Topologies.is_valid(topology::SquareGreedTopology, index::SquareGreedIndex)
    return (1 <= index.x <= topology.width &&
            1 <= index.y <= topology.height)
end


Topologies.index_type(::SquareGreedTopology) = SquareGreedIndex


# TODO: check if indexes generated in column-first order
function Topologies.coordinates(topology::SquareGreedTopology)
    return (SquareGreedIndex(x, y) for y=1:topology.height, x=1:topology.width)
end


function manhattan_distance(a::SquareGreedIndex, b::SquareGreedIndex=zero(SquareGreedIndex))
    return abs(a.x-b.x) + abs(a.y-b.y)
end


function ring_distance(a::SquareGreedIndex, b::SquareGreedIndex=zero(SquareGreedIndex))
    return max(abs(a.x-b.x), abs(a.y-b.y))
end


function euclidean_distance(a::SquareGreedIndex, b::SquareGreedIndex=zero(SquareGreedIndex))
    return sqrt((a.x-b.x)^2 + abs(a.y-b.y)^2)
end


end
