
module Topologies

export Topology, TopologyIndex, coordinates, is_valid, storage_index


abstract type Topology end
abstract type TopologyIndex end


# TODO: specify types

function coordinates end

function storage_index end

function is_valid end


module SquareGreedTopologies

export SquareGreedIndex, SquareGreedTopology, square_area_template, SquareGreedIndexes, SquareGreedNeighborhood

using ...PCG.Types
using ...PCG.Geometry: Point
using ...PCG.Topologies
using ...PCG.Topologies: Topology, TopologyIndex, coordinates


const SquareGreedSize = Int64


struct SquareGreedIndex <: TopologyIndex
    x::SquareGreedSize
    y::SquareGreedSize
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


# TODO: check if indexes generated in column-first order
function Topologies.coordinates(topology::SquareGreedTopology)
    return (SquareGreedIndex(x, y) for y=1:topology.height, x=1:topology.width)
end


function square_distance(a::SquareGreedIndex, b::SquareGreedIndex=SquareGreedIndex(0, 0))
    return max(abs(a.x-b.x), abs(a.y-b.y))
end


function square_area_template(min_distance::SquareGreedSize, max_distance::SquareGreedSize)
    # TODO: reserve correct array size
    area = SquareGreedIndexes()

    for dx in (-max_distance):(max_distance + 1)
        for dy in (-max_distance):(max_distance + 1)

            index = SquareGreedIndex(dx, dy)

            if min_distance <= square_distance(index) <= max_distance
                push!(area, index)
            end
        end
    end

    return area
end


struct SquareGreedNeighborhood
    template::SquareGreedIndexes

    function SquareGreedNeighborhood()
        # TODO: refactor to parametrized template
        template = square_area_template(1, 1)
        return new(template)
    end

end



function (neighborhood::SquareGreedNeighborhood)(element::E) where E
    # TODO: create metafunction
    elements = reserve_area!(element, length(neighborhood.template))

    # TODO: optimize?
    fill!(elements, disable(element))

    for (i, delta) in enumerate(neighborhood.template)
        coordinates = element.topology_index + delta

        # TODO: do smth with that
        if is_valid(element.universe.topology, coordinates)
            elements[i] = construct_element(E, element.universe, coordinates)
        end
    end

    return elements
end


end

end
