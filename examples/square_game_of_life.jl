
using Images

using PCG
using PCG.Geometry
using PCG.SquareGreed
using PCG.Topologies
using PCG.Recorders.SquareGreedImage
using PCG.Recorders.TurnsLogger
using PCG.Spaces

using PCG.Types

############################################
# temporary code
############################################

# TODO: remove
const CELL_SIZE = Size(5, 5)


struct Fraction
    border::Float32
end


#########################
# ? filters
#########################

struct All
    space::Space
end


function (all::All)()
    return all.space._base_nodes
end


struct Neighbors
    indexes::Any

    function Neighbors(topology::Topology)
        template = square_area_template(1, 1)
        indexes = area(topology, template)
        return new(indexes)
    end

end


function (connectome::Neighbors)(node::Node)
    return [space._base_nodes[index]
            for index in connectome.indexes[node.index]
            if node.index != index]
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
function initialize(space::Space{Node}, coordinates::SquareCells)

    for cell in coordinates
        node = Node()
        node.properties = NodeProperties(DEAD)
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

function filter(nodes::Array{Node, 1}, parameters::State)
    return [node for node in nodes if check(node, parameters)]
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

space = Space{Node}([drawer, turns_logger])
initialize(space, cells_rectangle(WIDTH, HEIGHT))

# TODO: all filters must be updated on topology update
#       better to check topology version on each filter call?
all = All(space)
neighbors = Neighbors(topology)

##########
# generate
##########

for node in all()
    # TODO: construct Fraction(0.2) only once
    if check(node, Fraction(0.2))
        node.properties.state = ALIVE  # TODO: rewrite for macros or smth else
    end
end

apply_changes(space)


for i in 1:TURNS
    for node in all()
        if check(node, ALIVE)
            if !(2 <= length(filter(neighbors(node), ALIVE)) <= 3)
                change_state(node, DEAD)
            end
        end

        if check(node, DEAD)
            if length(filter(neighbors(node), ALIVE)) == 3
                change_state(node, ALIVE)
            end
        end
    end

    apply_changes(space)

end

save_image(drawer, "output.webm")

print("\n\nprocessed\n")
