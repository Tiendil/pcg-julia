
# extenral packages:
#
# - JuliaImages
# - FileIO
# - ImageMagick
# - Reel
#

using Images, FileIO, Reel

############################################
# temporary code
############################################

struct Point
    x::Float32
    y::Float32
end


Base.ceil(point::Point) = Point(ceil(point.x),
                                ceil(point.y))

Base.:-(a::Point, b::Point) = Point(a.x - b.x,
                                    a.y - b.y)

Base.:*(a::Point, b::Point) = Point(a.x * b.x,
                                    a.y * b.y)

Base.:/(a::Point, b::Int64) = Point(a.x / b,
                                    a.y / b)

const Points = Array{Point, 1}


# TODO: remove
const CELL_SIZE = Point(5, 5)


struct Size
    x::Float32
    y::Float32
end

# TODO: bad decision?
Base.:*(a::Size, b::Point) = Point(a.x * b.x,
                                   a.y * b.y)


struct BoundingBox
    x_min::Float32
    x_max::Float32
    y_min::Float32
    y_max::Float32
end


Base.:+(a::BoundingBox, b::BoundingBox) = BoundingBox(min(a.x_min, b.x_min),
                                                      max(a.x_max, b.x_max),
                                                      min(a.y_min, b.y_min),
                                                      max(a.y_max, b.y_max))

BoundingBox() = BoundingBox(0.0, 0.0, 0.0, 0.0)

BoundingBox(point::Point) = BoundingBox(point.x, point.x + 1,
                                        point.y, point.y + 1)

BoundingBox(points::Points) = reduce(+, BoundingBox.(points), init=BoundingBox(points[1]))


Size(box::BoundingBox) = Size(box.x_max - box.x_min,
                              box.y_max - box.y_min)


struct Sprite
    color::Any
    _image::Any
end

Sprite(color) = Sprite(color, fill(color, (Int64(CELL_SIZE.y), Int64(CELL_SIZE.x))))


struct Biome
    checker::Any
    sprite::Sprite
end


mutable struct Drawer
    cell_size::Point
    duration::Int32
    filename::String

    _biomes::Array{Biome, 1}
    _frames::Array{Any, 1}
end

Drawer(cell_size::Point, duration::Int32, filename::String) = Drawer(cell_size,
                                                                     duration,
                                                                     filename,
                                                                     [],
                                                                     [])



function add_biome(drawer::Drawer, biome::Biome)
    push!(drawer._biomes, biome)
end


function save_image(drawer::Drawer, filename::String)

    frames = Frames(MIME("image/png"), fps=1.0 / (drawer.duration / 1000))

    # TODO: rewrite to dot syntax
    for frame in drawer._frames
        push!(frames, frame)
    end

    write(filename, frames)
end


struct Cell
    x::Int32
    y::Int32
end

Cell() = Cell(0, 0)

# TODO: must differe between different topologies
const Cells = Array{Cell, 1}

Point(cell::Cell) = Point(cell.x, cell.y)


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
    _connectomes::Array{Any, 1}
    _indexes::Dict{Point, Union{Nothing, Int64}}
end

Topology(coordinates) = Topology([],
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
    _recorders::Array{Drawer}
end

Space{NODE}(topology::Topology, recorders::Array{Drawer}) where NODE = Space{NODE}([], [], topology, recorders)


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
end

Node() = Node(nothing)

# TODO: is it right?
Base.zero(::Type{Node}) = Node(nothing)


# TODO: replace with template copy method?
function copy(node::Node)
    return Node(index=node.index,
                coordinates=node.coordinates,
                _new_node=nothing,
                space=node.space,
                properties=copy(node.properties))
end


function calculate_canvas_size(recorder::Drawer, nodes::Array{Node, 1})

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

    # return new_nodes
end


base_nodes(callback::Any, space::Space{Node}, filter::Any) = base_nodes(callback, space, filter, 1:length(space))


function node_position(recorder::Drawer, node::Node, canvas_size::Point)
    # TODO: is it right?
    return (node.coordinates - Point(1.0, 1.0)) * recorder.cell_size
end


function record_state(space::Space{Node}, recorder::Drawer)

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


Base.zero(::Type{NodeProperties}) = NodeProperties(DEAD)


# TODO: what convention for name of that method in julia?
# TODO: rewrite to call(a, b, c) do … end syntax ? where … is node fabric
function initialize(space::Space{Node}, base_node::Node)
    base_node.space = space

    space._base_nodes = [Node() for _ in 1:length(space.topology)]
    space._new_nodes = typeof(space._new_nodes)(nothing, length(space.topology))

    for (i, coordinates) in enumerate(coordinates(space.topology))
        node = space._base_nodes[i]

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


function choose_biome(drawer::Drawer, node::Node)
    for biome in drawer._biomes
        if check_node(node, biome.checker)
            return biome
        end
    end
end


############
# visualizer
############

drawer = Drawer(CELL_SIZE, convert(Int32, 100), "./example.webp")

add_biome(drawer, Biome(ALIVE, Sprite(RGBA(1, 1, 1))))
add_biome(drawer, Biome(DEAD, Sprite(RGBA(0, 0, 0))))
# add_biome(drawer, Biome(All(), Sprite(RGBA(1, 0, 0))))

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

# for i in range(STEPS):
#     print("step $(i+1)/$STEPS")

#     space.step() do space

#         space.base(ALIVE) do node
#             if square_grid.Ring(node).base(ALIVE) | ~Between(2, 3):
#                 node <<= DEAD
#             end
#         end

#         space.base(DEAD) do node
#             if square_grid.Ring(node).base(ALIVE) | Count(3):
#                 node <<= ALIVE
#             end
#         end

#     end

# end

save_image(drawer, "output.webm")

print("\n\nprocessed\n")
