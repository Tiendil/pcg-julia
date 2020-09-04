
using Images

using PCG
using PCG.Geometry
# using PCG.SquareGreed
using PCG.Topologies
using PCG.Topologies.SquareGreedTopologies
using PCG.Recorders.SquareGreedImage
using PCG.Recorders.TurnsLogger
using PCG.Spaces
using PCG.Spaces.LinearSpaces

using PCG.Types


##########################
# code for intergration
##########################


@enum State begin
    DEAD
    ALIVE
end


# TODO: specify parent class
struct Properties
    state::State
end


# TODO: does name correct
# TODO: does topology attribute requred (SquareGreedIndex should contain all required information)
function to_index(topology::SquareGreedTopology, i::SquareGreedIndex)
    return LinearSpaceIndex((i.y - 1) * topology.height + i.x)
end


# TODO: make template properties
struct Element
    topology_index::SquareGreedIndex
    space_index::LinearSpaceIndex
    node::SpaceNode{Properties}
end

#########################
# ? filters
#########################

struct All{P}
    space::LinearSpace{P}
    topology::SquareGreedTopology
end


function (all::All)()
    return (Element(i, to_index(all.topology, i), get_node(all.space, to_index(all.topology, i)))
            for i in nodes_coordinates(all.topology))
end


# TODO: can we create universal predicates?
struct Neighbors{P}
    space::LinearSpace{P}
    topology::SquareGreedTopology
    template::SquareGreedIndexes

    function Neighbors(space::LinearSpace{P}, topology::SquareGreedTopology) where P
        template = square_area_template(1, 1)
        return new{P}(space, topology, template)
    end

end


const AreaElements = Vector{Union{Element, Nothing}}


# TODO: here must be a generator?
function Base.count(nodes::AreaElements)
    counter = 0

    for node in nodes
        if !isnothing(node)
            counter += 1
        end
    end

    return counter
end


# TODO: rewrite to cache? (again…)
function (connectome::Neighbors)(element::Element)
    elements = AreaElements(nothing, length(connectome.template))

    for i in eachindex(connectome.template)
        coordinates = element.topology_index + connectome.template[i]

        # TODO: do smth with that
        if is_valid(topology, coordinates)
            space_index = to_index(connectome.topology, coordinates)

            elements[i] = Element(coordinates,
                                  space_index,
                                  get_node(connectome.space, space_index))
        end
    end

    return elements
end


struct Fraction
    border::Float32
end


function (fraction::Fraction)(element::Element)
    return check(element.node, fraction)
end


############################################

const TURNS = 100
const WIDTH = 80
const HEIGHT = 80
const CELL_SIZE = Size(5, 5)
const DEBUG = false


function (state::State)(element::Element)
    return check(element.node, state)
end

function (state::State)(elements::AreaElements)
    # TODO: replace with boolean template assigment

    for (i, element) in enumerate(elements)
        if isnothing(element) || check(element.node, state)
            continue
        end

        elements[i] = nothing
    end

    return elements
end

using InteractiveUtils

# TODO: replace with more abstract logic
function change_state(space::Space, element::Element, state::State)
    new_node = SpaceNode(element.node.current,
                         Properties(state),
                         space.turn)

    # @code_warntype
    set_node!(space, element.space_index, new_node)
end


# TODO: choose better name?
# TODO: specify inheritance?
function Spaces.check(node::SpaceNode, parameters::Fraction)
    return rand(Float32) < parameters.border
end


# TODO: specify inheritance?
function Spaces.check(node::SpaceNode, parameters::State)
    return node.current.state == parameters
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

topology = SquareGreedTopology(WIDTH, HEIGHT)

base_property = Properties(DEAD)
space_size = WIDTH * HEIGHT


if DEBUG
    space = LinearSpace(base_property, space_size)
else
    space = LinearSpace(base_property,
                        space_size,
                        # [turns_logger])
                        [drawer, turns_logger])
end

# initialize(space, cells_rectangle(WIDTH, HEIGHT))

# todo: all filters must be updated on topology update
#       better to check topology version on each filter call?
all = All(space, topology)
neighbors = Neighbors(space, topology)

##########
# generate
##########

for element in all()
    # TODO: construct Fraction(0.2) only once
    # TODO: move Fraction up
    if element |> Fraction(0.2)
        change_state(space, element, ALIVE)  # TODO: rewrite for macros or smth else
    end
end

apply_changes!(space, topology)


@time for i in 1:TURNS
    for element in all()

        # @time element |> neighbors |> ALIVE |> count

        if (element |> ALIVE &&
            element |> neighbors |> ALIVE |> count ∉ 2:3)
            change_state(space, element, DEAD)
        end

        if (element |> DEAD &&
            element |> neighbors |> ALIVE |> count == 3)
            change_state(space, element, ALIVE)
        end
    end

    apply_changes!(space, topology)

end


if !DEBUG
    save_image(drawer, "output.webm")
end

println("processed")
