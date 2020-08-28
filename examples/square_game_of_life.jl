
# extenral packages:
#
# - JuliaImages
# - FileIO
# - ImageMagick
# - Reel
#

using Images

using PCG
using PCG.Geometry
using PCG.Drawer

############################################
# temporary code
############################################

# TODO: remove
const CELL_SIZE = Size(5, 5)

struct Cell
    x::Int32
    y::Int32
end

Cell() = Cell(0, 0)

# TODO: must differe between different topologies
const Cells = Array{Cell, 1}

PCG.Geometry.Point(cell::Cell) = Point(cell.x, cell.y)

Base.:+(a::Point, b::Cell) = Point(a.x + b.x,
                                   a.y + b.y)


# TODO: rewrite to Channel or other generator
function cells_rectangle(width::Int64, height::Int64)
    # TODO: rewrite
    cells = [Cell() for _ in 1:width*height]

    i = 1

    # TODO: rewrite to single loop
    for y in 1:height,
        x in 1:width
        cells[i] = Cell(x, y)
        i += 1
    end

    return cells
end


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


mutable struct Space{NODE}
    _base_nodes::Array{NODE}
    _new_nodes::Array{Union{Nothing, NODE}}
    topology::Topology
    _recorders::Array{Recorder}
end

Space{NODE}(topology::Topology, recorders::Array{Recorder}) where NODE = Space{NODE}([], [], topology, recorders)


function cells_bounding_box(cells::Cells)
    box = BoundingBox(cells[1])

    # TODO: rewrite to reduce or smth else?
    for cell in cells[2:end]
        # TODO: rewrite to convert or smth else
        box += BoundingBox(cell)
    end

    return box

end



mutable struct Node
    index::Int32
    coordinates::Point
    _new_node::Union{Nothing, Node}
    space::Union{Nothing, Space}

    # TODO: replace Any with template parameter declaration
    properties::Any

    Node(properties::Any) = new(0, Point(0, 0), nothing, nothing, properties)
    function Node(index::Int32, coordinates::Point, _new_node::Union{Nothing, Node}, space::Union{Nothing, Space}, properties::Any)
        return new(index, coordinates, _new_node, space, properties)
    end
end

Node() = Node(nothing)

# TODO: is it right?
Base.zero(::Type{Node}) = Node(nothing)


# TODO: replace with template copy method?
function copy(node::Node)
    return Node(node.index,
                node.coordinates,
                nothing,
                node.space,
                copy(node.properties))
end


function calculate_canvas_size(recorder::Recorder, nodes::Array{Node, 1})

    # TODO: rewrite to redefiend function?
    if isempty(nodes)
        return BoundingBox()
    end

    coordinates = [node.coordinates for node in nodes]

    return ceil(Size(BoundingBox(coordinates)) * recorder.cell_size)
end


Base.length(space::Space{Node}) = length(space._base_nodes)


function record_state(space::Space{Node})
    for recorder in space._recorders
        record_state(space, recorder)
    end
end


function step(callback::Any, space::Space{Node})

    callback(space)

    for (i, node) in enumerate(space._new_nodes)
        if !isnothing(node)
            space._base_nodes[i] = node
            space._new_nodes[i] = nothing
        end
    end

    record_state(space)
end


# TODO: replace Any with appropriate type
# TODO: does "callback" good solution?
function base_nodes(callback::Any, space::Space{Node}, filter::Any, indexes::Any)
    for i in indexes
        node = space._base_nodes[i]

        if check(filter, node)
            callback(node)
        end
    end

end


base_nodes(callback::Any, space::Space{Node}, filter::Any) = base_nodes(callback, space, filter, 1:length(space))

function node_position(recorder::Recorder, node::Node, canvas_size::Size)
    # TODO: is it right?
    return (node.coordinates - Point(1.0, 1.0)) * recorder.cell_size
end


function record_state(space::Space{Node}, recorder::Recorder)

    canvas_size = calculate_canvas_size(recorder, space._base_nodes)

    # TODO: fill with monotone color (use zeros? https://docs.julialang.org/en/v1/base/arrays/#Base.zeros)
    canvas = rand(RGB, Int64(canvas_size.y), Int64(canvas_size.x))

    for node in space._base_nodes
        biome = choose_biome(recorder, node)

        position = node_position(recorder, node, canvas_size)

        image = biome.sprite._image

        # TODO: move out?
        sprite_size = size(image)

        x = Int64(position.x) + 1
        y = Int64(position.y) + 1

        # TODO: round position correctly
        copyto!(canvas,
                # TODO: does indexes places right?
                # TODO: fix size calculation
                CartesianIndices((x:(x+sprite_size[1]-1), y:(y+sprite_size[2]-1))),
                image,
                CartesianIndices((1:sprite_size[1], 1:sprite_size[2])))
    end

    push!(recorder._frames, canvas)
end


struct Fraction
    border::Float32
end

# TODO: choose better name?
function check(parameters::Fraction, node::Node)
    return rand(Float32) < parameters.border
end


function square_distance(a::Cell, b::Cell=Cell(0.0, 0.0))
    return max(abs(a.x-b.x), abs(a.y-b.y))
end


function square_area_template(min_distance::Int64, max_distance::Int64)
    area = []

    for dx in (-max_distance):(max_distance + 1)
        for dy in (-max_distance):(max_distance + 1)

            cell = Cell(dx, dy)

            if min_distance <= square_distance(cell) <= max_distance
                push!(area, cell)
            end
        end
    end

    return area
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


function square_area(topology::Topology, min_distance::Int64, max_distance::Int64)
    cache::Array{Union{Nothing, Any}} = [nothing for _ in 1:length(topology)]

    template = square_area_template(min_distance, max_distance)

    for (center, index) in topology._indexes
        points = [center + point for point in template]
        # println("---------------")
        # println("center: $center")
        # println("index: $index")
        # println("points: $points")

        cache[index] = area_indexes(topology, points)
    end

    return cache
end


function square_ring_connectom(topology::Topology, min_distance::Int64, max_distance=Int64)
    return square_area(topology, min_distance, max_distance)
end


struct Area
    space::Space{Node}
    indexes::Any

    function Area(node::Node, min_distance=1, max_distance=nothing)
        if isnothing(max_distance)
            max_distance = min_distance
        end

        # TODO: replace first part of uid (was "self.__class__.__name__") to smth else
        # TODO: make better (by performance) key
        connectome_uid = "xxx-$min_distance-$max_distance"

        if haskey(node.space.topology._connectomes, connectome_uid)
            connectome = node.space.topology._connectomes[connectome_uid]
        else
            connectome = square_ring_connectom(node.space.topology, min_distance, max_distance)
            node.space.topology._connectomes[connectome_uid] = connectome
        end

        return new(node.space, connectome[node.index])
    end

end


function area_nodes(area::Area, filter::Any)
    nodes = []

    # println(area.indexes)
    for i in area.indexes
        node = space._base_nodes[i]

        if check(filter, node)
            push!(nodes, node)
        end
    end

    return nodes
end


############################################

const STEPS = 100
const WIDTH = 80
const HEIGHT = 80


@enum State begin
    DEAD
    ALIVE
end


mutable struct NodeProperties
    state::State
end


function copy(properties::NodeProperties)
    return NodeProperties(properties.state)
end


function check(parameters::State, node::Node)
    return node.properties.state == parameters
end


# TODO: replace with more abstract logic
function change_state(node::Node, state::State)
    if isnothing(node._new_node)
        # TODO: does two instances required?
        node._new_node = copy(node)
        node.space._new_nodes[node.index] = node._new_node
    end

    node._new_node.properties.state = state
end


Base.zero(::Type{NodeProperties}) = NodeProperties(DEAD)


# TODO: what convention for name of that method in julia?
# TODO: rewrite to call(a, b, c) do … end syntax ? where … is node fabric
function initialize(space::Space{Node}, base_node::Node)

    space._base_nodes = [Node() for _ in 1:length(space.topology)]
    space._new_nodes = typeof(space._new_nodes)(nothing, length(space.topology))

    for (i, coordinates) in enumerate(coordinates(space.topology))
        node = space._base_nodes[i]

        node.space = space
        node.coordinates = coordinates
        node.index = i
        node.properties = zero(NodeProperties)

        # TODO: is that working?
        register_index!(space.topology, coordinates, i)
    end

    record_state(space)
end



function check_node(node::Node, state::State)
    return node.properties.state == state
end


function choose_biome(drawer::Recorder, node::Node)
    for biome in drawer._biomes
        if check_node(node, biome.checker)
            return biome
        end
    end
end


############
# visualizer
############

drawer = Recorder(CELL_SIZE, convert(Int32, 100), "./example.webp")

add_biome(drawer, Biome(ALIVE, Sprite(RGBA(1, 1, 1), CELL_SIZE)))
add_biome(drawer, Biome(DEAD, Sprite(RGBA(0, 0, 0), CELL_SIZE)))
# add_biome(drawer, Biome(All(), Sprite(RGBA(1, 0, 0), CELL_SIZE)))

###########
# generator
###########

topology = Topology(cells_rectangle(WIDTH, HEIGHT))

space = Space{Node}(topology, [drawer])
initialize(space, Node(NodeProperties(DEAD)))

##########
# generate
##########

step(space) do space

    # TODO: rewrite?
    base_nodes(space, Fraction(0.2)) do node
        node.properties.state = ALIVE  # TODO: rewrite for macros or smth else
    end
end

for i in 1:STEPS
    println("step $(i+1)/$STEPS")

    step(space) do space

        base_nodes(space, ALIVE) do node
            # TODO replace with chain calculation
            if !(2 <= length(area_nodes(Area(node), ALIVE)) <= 3)
                change_state(node, DEAD)
            end
        end

        base_nodes(space, DEAD) do node
            if length(area_nodes(Area(node), ALIVE)) == 3
                change_state(node, ALIVE)
            end
        end

    end

end

save_image(drawer, "output.webm")

print("\n\nprocessed\n")
