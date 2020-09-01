
using Images

using PCG
using PCG.Geometry
using PCG.SquareGreed
using PCG.Topologies
using PCG.Recorders.SquareGreedImage
using PCG.Recorders.TurnsLogger
using PCG.Spaces

using PCG.Types

#########################
# ? filters
#########################

struct All
    space::Space
end


function (all::All)()
    return all.space._base_nodes
end


const AreaNodes = Array{Union{Node, Nothing}, 1}

mutable struct AreaNodesElement
    used::Bool
    area::AreaNodes
end


mutable struct AreaNodesCache
    areas::Array{AreaNodesElement, 1}

    AreaNodesCache() = new(Array{AreaNodesElement, 1}())
end


function reserve_area!(cache::AreaNodesCache, size::Int64)
    for element in cache.areas
        if !element.used && length(element.area) == size
            element.used = true
            return element.area
        end
    end

    area = AreaNodes(undef, size)
    push!(cache.areas, AreaNodesElement(true, area))

    return area
end


function release_area!(cache::AreaNodesCache, area::AreaNodes)
    for element in cache.areas
        if element.area === area
            element.used = false
            return
        end
    end
end


function release_all_areas!(cache::AreaNodesCache)
    for element in cache.areas
        element.used = false
    end
end


struct Neighbors
    indexes::Any
    cache::AreaNodesCache

    function Neighbors(topology::Topology)
        template = square_area_template(1, 1)
        indexes = area(topology, template)
        return new(indexes, AreaNodesCache())
    end

end


function Base.count(nodes::AreaNodes)
    counter = 0

    # println([isnothing(node) ? '?' : node.properties.state for node in nodes])

    for node in nodes
        if !isnothing(node)
            counter += 1
        end
    end

    return counter
end


function (connectome::Neighbors)(node::Node)
    indexes = connectome.indexes[node.index]
    nodes = reserve_area!(connectome.cache, length(indexes))

    nodes .= getindex.((space._base_nodes,), indexes)

    return nodes
end


struct Fraction
    border::Float32
end


function (fraction::Fraction)(node::Node)
    return check(node, fraction)
end


############################################

const TURNS = 100
const WIDTH = 80
const HEIGHT = 80
const CELL_SIZE = Size(5, 5)
const DEBUG = true

@enum State begin
    DEAD
    ALIVE
end


function (state::State)(node::Node)
    return check(node, state)
end

function (state::State)(nodes::AreaNodes)
    for (i, node) in enumerate(nodes)
        if isnothing(node) | check(node, state)
            continue
        end

        nodes[i] = nothing
    end

    return nodes
end


mutable struct Properties <: NodeProperties
    state::State
end


# TODO: replace with more abstract logic
function change_state(space::Space, node::Node, state::State)
    if node.index_in_new == 0
        push!(space._new_nodes, deepcopy(node))
        node.index_in_new = length(space._new_nodes)
    end

    space._new_nodes[node.index_in_new].properties.state = state
end


Base.zero(::Type{Properties}) = Properties(DEAD)


# TODO: what convention for name of that method in julia?
# TODO: rewrite to call(a, b, c) do … end syntax ? where … is node fabric
function initialize(space::Space{Node{Properties}}, coordinates::SquareCells)

    for cell in coordinates
        node = Node(Properties(DEAD))

        node.coordinates = Point(cell)

        # TODO: remove ambiguous name register! ??
        Spaces.register!(space, node)
        Topologies.register!(topology, node.coordinates, node.index)
    end

    record_state(space)
end


# TODO: choose better name?
function Spaces.check(node::Node, parameters::Fraction)
    return rand(Float32) < parameters.border
end


function Spaces.check(node::Node, parameters::State)
    return node.properties.state == parameters
end


############
# recorders
############

drawer = SquareGreedImageRecorder(CELL_SIZE, convert(Int32, 100))

add_biome(drawer, Biome(ALIVE, Sprite(RGBA(1, 1, 1), CELL_SIZE)))
add_biome(drawer, Biome(DEAD, Sprite(RGBA(0, 0, 0), CELL_SIZE)))
# add_biome(drawer, Biome(All(), Sprite(RGBA(1, 0, 0), CELL_SIZE)))

turns_logger = TurnsLoggerRecorder(0, TURNS + 2)

###########
# generator
###########

topology = Topology()

if DEBUG
    space = Space{Node{Properties}}()
else
    space = Space{Node{Properties}}([drawer, turns_logger])
end

initialize(space, cells_rectangle(WIDTH, HEIGHT))

# todo: all filters must be updated on topology update
#       better to check topology version on each filter call?
all = All(space)
neighbors = Neighbors(topology)

##########
# generate
##########

for node in all()
    # TODO: construct Fraction(0.2) only once
    if node |> Fraction(0.2)
        change_state(space, node, ALIVE)  # TODO: rewrite for macros or smth else
    end
end

apply_changes(space)


@time for i in 1:TURNS
    for node in all()
        if (node |> ALIVE &&
            node |> neighbors |> ALIVE |> count ∉ 2:3)
            change_state(space, node, DEAD)
        end

        if (node |> DEAD &&
            node |> neighbors |> ALIVE |> count == 3)
            change_state(space, node, ALIVE)
        end

        # TODO: hide in api
        release_all_areas!(neighbors.cache)
    end

    apply_changes(space)

end


if !DEBUG
    save_image(drawer, "output.webm")
end

println("cached: $(length(neighbors.cache.areas))")

println("processed")
