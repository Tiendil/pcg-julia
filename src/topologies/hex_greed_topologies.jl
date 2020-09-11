
# https://www.redblobgames.com/grids/hexagons/implementation.html

module HexGreedTopologies

export HexGreedIndex, HexGreedTopology, square_area_template, HexGreedIndexes, HexGreedNeighborhood, CELL_SIZE, cell_bounding_box, cell_center, cell_corners

using ...PCG.Types
using ...PCG.Geometry: Point, BoundingBox, Size
using ...PCG.Topologies
using ...PCG.Topologies: Topology, TopologyIndex, coordinates


const HexGreedSize = Int64


struct HexGreedIndex <: TopologyIndex
    q::HexGreedSize
    r::HexGreedSize
    s::HexGreedSize
end


Base.:+(a::HexGreedIndex, b::HexGreedIndex) = HexGreedIndex(a.q + b.q,
                                                            a.r + b.r,
                                                            a.s + b.s)

Base.:-(a::HexGreedIndex, b::HexGreedIndex) = HexGreedIndex(a.q - b.q,
                                                            a.r - b.r,
                                                            a.s - b.s)


Base.:*(a::HexGreedIndex, b::Number) = HexGreedIndex(a.q * b,
                                                     a.r * b,
                                                     a.s * b)


HexGreedIndexQR(q::HexGreedSize, r::HexGreedSize) = HexGreedIndex(q, r, -q-r)


const HexGreedIndexes = Vector{HexGreedIndex}


const DIRECTIONS = [HexGreedIndex(1, 0, -1),
                    HexGreedIndex(1, -1, 0),
                    HexGreedIndex(0, -1, 1),
                    HexGreedIndex(-1, 0, 1),
                    HexGreedIndex(-1, 1, 0),
                    HexGreedIndex(0, 1, -1)]


function neighbourof(i::HexGreedIndex, n::Integer)
    # TODO: change to "n % 6"
    return i + DIRECTIONS[n]
end


function neighboursof(i::HexGreedIndex)
    # TODO: rewrite to "." operation
    return [i + di for di in DIRECTIONS]
end


struct Orientation
    f0::Float64
    f1::Float64
    f2::Float64
    f3::Float64

    b0::Float64
    b1::Float64
    b2::Float64
    b3::Float64
end


const LAYOUT_POINTY = Orientation(sqrt(3.0), sqrt(3.0) / 2.0, 0.0, 3.0 / 2.0,
                                  sqrt(3.0) / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0)


function cell_corner_offset(corner::Integer)
    angle = 2.0 * pi * (0.5 + (corner-1)) / 6
    return Point(cos(angle), sin(angle))
end


const CELL_CORNERS_OFFSETS = [cell_corner_offset(i) for i in 1:6]


function normal_cell_size()
    min_x, max_x = 0, 0
    min_y, max_y = 0, 0

    for corner in CELL_CORNERS_OFFSETS
        min_x = min(min_x, corner.x)
        max_x = max(max_x, corner.x)
        min_y = min(min_y, corner.y)
        max_y = max(max_y, corner.y)
    end

    return Size(max_x - min_x, max_y - min_y)
end


function cell_center(cell::HexGreedIndex)
    x = (LAYOUT_POINTY.f0 * cell.q + LAYOUT_POINTY.f1 * cell.r)
    y = (LAYOUT_POINTY.f2 * cell.q + LAYOUT_POINTY.f3 * cell.r)
    return Point(x, y)
end


function cell_corners(cell::HexGreedIndex)
    center = cell_center(cell)
    return [center + offset for offset in CELL_CORNERS_OFFSETS]
end


function cell_bounding_box(cell)
    corners = cell_corners(cell)
    return BoundingBox(corners)
end


# TODO: do not export or rename
const CELL_SIZE = normal_cell_size()



function cells_hexagon(radius)
    return (HexGreedIndexQR(q, r)
            for q in (-radius:radius)
            for r in max(-radius, -q - radius):min(radius, -q + radius))
end


struct HexGreedTopology <: Topology
    radius::HexGreedSize
end


function Topologies.is_valid(topology::HexGreedTopology, index::HexGreedIndex)
    return hex_length(index) <= topology.radius
end


# TODO: check if indexes generated in column-first order
function Topologies.coordinates(topology::HexGreedTopology)
    return cells_hexagon(topology.radius)
end


function hex_length(cell::HexGreedIndex)
    return trunc(HexGreedSize, (abs(cell.q) + abs(cell.r) + abs(cell.s)) / 2)
end


function hex_distance(a::HexGreedIndex, b::HexGreedIndex)
    return hex_length(a - b)
end


function cells_ring(center::HexGreedIndex, radius::HexGreedSize)

    if radius == 0
        return [center]
    end

    if radius == 1
        return neighboursof(center)
    end

    # TODO: reserve memory
    results = []

    cell_pointer = center + DIRECTIONS[5] * radius

    # TODO: replace with cartesian loop
    for i in 1:6
        for j in 1:radius
            push!(results, cell_pointer)
            cell_pointer = neighbourof(cell_pointer, i)
        end
    end

    return results
end


function hex_area_template(min_distance::HexGreedSize, max_distance::HexGreedSize)
    area = HexGreedIndexes()

    radius = 0
    max_distance_exceed = false

    center = HexGreedIndex(0, 0, 0)

    while !max_distance_exceed

        max_distance_exceed = true

        for cell in cells_ring(center, radius)
            cell_distance = hex_distance(center, cell)

            if cell_distance <= max_distance
                max_distance_exceed = false

                if min_distance <= cell_distance
                    push!(area, cell)
                end
            end
        end

        radius += 1
    end

    return area
end


struct HexGreedNeighborhood
    template::HexGreedIndexes

    function HexGreedNeighborhood()
        # TODO: refactor to parametrized template
        template = hex_area_template(1, 1)
        return new(template)
    end

end



function (neighborhood::HexGreedNeighborhood)(element::E) where E
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
