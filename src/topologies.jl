module Topologies

using ..PCG.Geometry: Point, Points
using ..PCG.Types: Cells
using ..PCG.Spaces: Space

export Topology, register!, area_indexes, area

const Index = Int64

mutable struct Topology
    # TODO: replace with function?
    _indexes::Dict{Point, Index}
end

Topology() = Topology(Dict{Point, Index}())

Base.length(topology::Topology) = length(topology._indexes)

# function coordinates(topology::Topology)
#     return keys(topology._indexes)
# end


# TODO: replace coordinates & index with node
function register!(topology::Topology, coordinates::Point, index::Index)
    topology._indexes[coordinates] = index
end


function area_indexes(topology::Topology, coordinates::Points)
    area::Array{Index, 1} = []

    for point in coordinates
        index = get(topology._indexes, point, nothing)

        if isnothing(index)
            continue
        end

        push!(area, index)
    end

    return area
end


function area(topology::Topology, template::Cells)
    cache::Array{Union{Nothing, Any}} = [nothing for _ in 1:length(topology)]

    for (center, index) in topology._indexes
        points = [center + point for point in template]
        cache[index] = area_indexes(topology, points)
    end

    return cache
end


end
