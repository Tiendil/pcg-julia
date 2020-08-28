module Topologies

using ..PCG.Geometry: Point, Points

export Topology, coordinates, register_index!, area_indexes

mutable struct Topology
    _connectomes::Dict{String, Any}
    _indexes::Dict{Point, Union{Nothing, Int64}}
end

Topology(coordinates) = Topology(Dict{String, Any}(),
                                 Dict(Point(cell) => nothing for cell in coordinates))

Base.length(topology::Topology) = length(topology._indexes)

function coordinates(topology::Topology)
    return keys(topology._indexes)
end


function register_index!(topology::Topology, coordinate::Point, index::Int64)
    topology._indexes[coordinate] = index
end


function area_indexes(topology::Topology, coordinates::Points)
    area = []

    for point in coordinates
        index = get(topology._indexes, point, nothing)

        if isnothing(index)
            continue
        end

        push!(area, index)
    end

    return area
end


end
