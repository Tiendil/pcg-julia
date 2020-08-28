
using Images

using PCG
using PCG.Geometry
using PCG.SquareGreed
using PCG.Topologies
using PCG.Recorders
using PCG.Spaces

############################################
# temporary code
############################################

# TODO: remove
const CELL_SIZE = Size(5, 5)


function node_position(recorder::Recorder, node::Node, canvas_size::Size)
    # TODO: is it right?
    return (node.coordinates - Point(1.0, 1.0)) * recorder.cell_size
end


function Spaces.record_state(space::Space{Node}, recorder::Recorder)

    canvas_size = ceil(space_size(space._base_nodes) * recorder.cell_size)

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


function square_area(topology::Topology, template::Cells)
    cache::Array{Union{Nothing, Any}} = [nothing for _ in 1:length(topology)]

    for (center, index) in topology._indexes
        points = [center + point for point in template]
        cache[index] = area_indexes(topology, points)
    end

    return cache
end


function square_ring_connectom(topology::Topology, min_distance::Int64, max_distance=Int64)
    template = square_area_template(min_distance, max_distance)
    return square_area(topology, template)
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

        if check(node, filter)
            push!(nodes, node)
        end
    end

    return nodes
end


############################################

const TURNS = 100
const WIDTH = 80
const HEIGHT = 80


@enum State begin
    DEAD
    ALIVE
end


mutable struct NodeProperties
    state::State
end


# TODO: replace with more abstract logic
function change_state(node::Node, state::State)
    if isnothing(node._new_node)
        # TODO: does two instances required?
        node._new_node = deepcopy(node)
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


# TODO: choose better name?
function Spaces.check(node::Node, parameters::Fraction)
    return rand(Float32) < parameters.border
end


function Spaces.check(node::Node, parameters::State)
    return node.properties.state == parameters
end


function choose_biome(drawer::Recorder, node::Node)
    for biome in drawer._biomes
        if check(node, biome.checker)
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

turn(space) do space

    # TODO: rewrite?
    base_nodes(space, Fraction(0.2)) do node
        node.properties.state = ALIVE  # TODO: rewrite for macros or smth else
    end
end

for i in 1:TURNS
    println("turn $(i+1)/$TURNS")

    turn(space) do space

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
