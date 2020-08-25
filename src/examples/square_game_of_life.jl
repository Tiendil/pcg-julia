
############################################
# temporary code
############################################

struct Point
    x::Float32
    y::Float32
end


struct RGBA
    r::Float32
    g::Float32
    b::Float32
    a::Float32
end

RGBA(r, g, b) = RGBA(r, g, b, a=1.0)


struct Sprite
    color::Any
    _image::Any
end

Sprite(color) = Sprite(color=color,
                       _image=missing)


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

Drawer(cell_size, duration, filename) = Drawer(cell_size,
                                               duration,
                                               filename,
                                               _biomes=[],
                                               _frames=[])

function record_state(space::Space, recorder::Drawer):
    # TODO: implement
    print("record state")
end


function save_image(drawer::Drawer)
    # TODO: implement
    print("save image")
end


struct Cell
    x::int32
    y::int32
end


const Cells = Array{Cells, 1, Size=0} where Size


# TODO: rewrite to Channel or other generator
function cells_rectangle(width::Int32, height::Int32)
    cells = Cells{width*height}

    i = 0

    # TODO: rewrite to single loop
    for y in range(0, height-1):
        for x in range(0, width-1):
            cells[i] = Cell(x, y)
            i += 1
        end
    end

    return cells
end


mutable struct Node
    index::Int32
    coordinates::Point
    _new_node::Union{Missing, Node}
    space::Union{Missing, Space}

    # TODO: replace Any with template parameter declaration
    properties::Any

    function Node(properties)
        return new(index=0,
                   coordinates=Point(0, 0),
                   _new_node=missing,
                   space=missing,
                   properties=properties)
    end
end


# TODO: replace with template copy method?
function copy(node::Node)
    return Node(index=node.index,
                coordinates=node.coordinates,
                _new_node=missing,
                space=node.space,
                properties=copy(node.properties))
end


mutable struct Topology
    _connectomes::Arrya{Any}
    _indexes::Dict{Point, Cells}
end

Topology(_connectomes) = Topology(_connectomes, _indexes={})

function size(topology::Topology)
    return size(topology._indexes)
end

function coordinates(topology::Topology)
    return keys(topology._indexes)
end


mutable struct Space
    _base_nodes::List{Node}
    _new_nodes::List{Node}
    topology::Topology
    recorders::List{Drawer}
end

Space(topology, recorders) = Space([], [], topology, recorders)

function size(space)
    return size(space._base_nodes)
end

# TODO: what convention for name of that method in julia?
# TODO: rewrite to call(a, b, c) do … end syntax ? where … is node fabric
function initialize(space::Space, base_node::Node):
    base_node.space = space

    space._base_nodes = [missing] * size(space.topology)
    self._new_nodes = [missing] * size(space.topology)

    for i, coordinates in enumerate(coordinates(space.topology)):
        node = copy(base_node)
        node.coordinates = coordinates
        node.index = i

        space._base_nodes[i] = node

        space.topology.register_index(coordinates, i)
    end

    self.record_state()

end

function record_state(space):
    for recorder in space.recorders:
        record_state(recorder, space)
    end
end


function step(callback, space::Space)

    callback(space)

    for i, node in enumerate(space._new_nodes):
        if ismissing(node):
            space._base_nodes[i] = node
            space._new_nodes[i] = missing
        end
    end

    record_state(space)
end


# TODO: replace Any with appropriate type
# TODO: does "callback" good solution?
function base_nodes(callback, space::Space, filter::Any, indexes::Any)
    for i in indexes:
        node = space._base_nodes[i]

        if check(filter, node):
            callback(node)
        end
    end

    return new_nodes
end


base_nodes(space::Space, filter::Any) = base_nodes(space, filter, range(0, size(space) - 1))


struct Fraction
    border::Float32
end

# TODO: choose better name?
function check(parameters::Fraction, node::Node)
    return rand(Float32) < parameters.fraction
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


############
# visualizer
############

drawer = Drawer(;cell_size=Point(5, 5),
                 duration=100,
                 filename="./example.webp")

add_biome(drawer, Biome(checker=ALIVE, sprite=Sprite(RGBA(1, 1, 1))))
add_biome(drawer, Biome(checker=DEAD, sprite=Sprite(RGBA(0, 0, 0))))
add_biome(drawer, Biome(checker=All(), sprite=Sprite(RGBA(1, 0, 0))))

###########
# generator
###########

topology = Topology(cells_rectangle(WIDTH, HEIGHT))

space = Space(topology, recorders=[drawer])
initialize(space, Node(NodeProperties(DEAD))

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

save_image(drawer)
