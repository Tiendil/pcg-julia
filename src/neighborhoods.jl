
module Neighborhoods

using ..PCG.Types
using ..PCG.Topologies

export Neighborhood


# TODO: make a template argument for all functions?
#       since distance can not be more complex value, than scalar
const Distance = Float64


struct NeighborhoodRange
    min_distance::Distance
    max_distance::Distance
end


function NeighborhoodRange()
    return new(one(Distance), one(Distance))
end


function NeighborhoodRange(distance::Distance)
    return new(distance, distance)
end


struct NeighborhoodTemplate{I<:TopologyIndex}
    range::NeighborhoodRange
    template::Vector{I}
end


struct Neighborhood{I<:TopologyIndex}
    index_type::Type{I}
    templates::Vector{NeighborhoodTemplate{I}}
    distance::Function

    function Neighborhood(topology::Topology, distance::Function)
        I = index_type(topology)
        return new{I}(I, NeighborhoodTemplate{I}[], distance)
    end
end


const Distances{I<:TopologyIndex} = Dict{I, Distance}


function get_min_distance(distances::Distances)
    min_index = nothing
    min_distance = Inf

    for (index, distance) in distances
        if distance < min_distance
            min_index = index
            min_distance = distance
        end
    end

    return (min_index, min_distance)
end


# TODO: rewrite to faster algorithm
function neighbors_before_distance(index::I, distance::Function, max_distance::Distance) where {I<:TopologyIndex}
    processed = Distances{I}()

    queue = Distances{I}()

    # theoretically, "zero" distance can be not equal to «number 0»
    queue[index] = distance(index, index)

    while !isempty(queue)

        min_index, min_distance = get_min_distance(queue)

        pop!(queue, min_index)

        processed[min_index] = min_distance

        for neighbor in neighborsof(min_index)

            if haskey(processed, neighbor) || haskey(queue, neighbor)
                continue
            end

            distance_to = distance(index, neighbor)

            if max_distance < distance_to
                continue
            end

            queue[neighbor] = distance_to
        end

    end

    return processed
end


function construct_template(neighborhood::Neighborhood{I}, range::NeighborhoodRange)::NeighborhoodTemplate{I} where {I<:TopologyIndex}

    neighbors = neighbors_before_distance(zero(neighborhood.index_type),
                                          neighborhood.distance,
                                          range.max_distance)

    area = Vector{neighborhood.index_type}()
    sizehint!(area, length(neighbors))

    for (index, distance_to) in neighbors
        if distance_to < range.min_distance
            continue
        end

        if range.max_distance < distance_to
            continue
        end

        push!(area, index)
    end

    return NeighborhoodTemplate{neighborhood.index_type}(range, area)
end


function (neighborhood::Neighborhood{I})(min_distance, max_distance)::NeighborhoodTemplate{I} where {I<:TopologyIndex}
    range = NeighborhoodRange(convert(Distance, min_distance),
                              convert(Distance, max_distance))

    for template in neighborhood.templates
        if template.range == range
            return template
        end
    end

    template = construct_template(neighborhood, range)

    push!(neighborhood.templates, template)

    return template
end


function (neighborhood::Neighborhood)(min_distance)
    return neighborhood(min_distance, min_distance)
end


function (neighborhood::Neighborhood)()
    return neighborhood(one(Distance), one(Distance))
end


function (neighborhood::NeighborhoodTemplate)(element::E) where E

    if !isenabled(element)
        return reserve_area!(element, 0)
    end

    template = neighborhood.template

    elements = reserve_area!(element, length(template))

    # TODO: optimize?
    fill!(elements, disable(element))

    for (i, delta) in enumerate(template)
        coordinates = element.topology_index + delta

        # TODO: do smth with that
        if is_valid(element.universe.topology, coordinates)
            elements[i] = construct_element(E, element.universe, coordinates)
        end
    end

    return elements
end


end
