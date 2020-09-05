
using InteractiveUtils

using Images

using PCG
using PCG.Geometry
using PCG.ArraysCaches
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


#########################
# ? filters
#########################

# TODO: make template properties
struct Element
    topology_index::SquareGreedIndex
    space_index::LinearSpaceIndex
    node::SpaceNode{Properties}
end


function Element(space::LinearSpace{Properties}, topology::SquareGreedTopology, i::SquareGreedIndex)
    space_index = to_index(topology, i)
    node = get_node(space, to_index(topology, i))
    return Element(i, space_index, node)
end


struct All
    space::LinearSpace{Properties}
    topology::SquareGreedTopology
end


function (all::All)(callback::Function)
    for i in nodes_coordinates(all.topology)
        element = Element(all.space, all.topology, i)
        callback(element)
    end

    apply_changes!(all.space, all.topology)
end


const AreaElements = Vector{Union{Element, Nothing}}


# TODO: can we create universal predicates?
struct Neighbors
    space::LinearSpace{Properties}
    topology::SquareGreedTopology
    template::SquareGreedIndexes
    cache::ArraysCache{AreaElements}

    function Neighbors(space::LinearSpace{Properties}, topology::SquareGreedTopology)
        template = square_area_template(1, 1)
        cache = ArraysCache{AreaElements}()
        return new(space, topology, template, cache)
    end

end


function ArraysCaches.release_all!(neighbors::Neighbors)
    release_all!(neighbors.cache)
end


# TODO: here must be a generator?
function Base.count(elements::AreaElements)
    counter = 0

    for element in elements
        if !isnothing(element)
            counter += 1
        end
    end

    return counter
end


# TODO: rewrite to cache? (again…)
function (neighbors::Neighbors)(element::Element)
    elements = reserve!(neighbors.cache, length(neighbors.template))

    for (i, delta) in enumerate(neighbors.template)
        coordinates = element.topology_index + delta

        # TODO: do smth with that
        if is_valid(neighbors.topology, coordinates)
            elements[i] = Element(neighbors.space,
                                  neighbors.topology,
                                  coordinates)
        end
    end

    return elements
end


struct Fraction
    border::Float32
end


function (fraction::Fraction)(element::Element)
    return check(element, fraction)
end


function (state::State)(element::Element)
    return check(element, state)
end

function (state::State)(elements::AreaElements)
    # TODO: replace with boolean template assigment

    for (i, e) in enumerate(elements)
        if !isnothing(e) && !check(e, state)
            elements[i] = nothing
        end
    end

    return elements
end


############################################

const TURNS = 100
const WIDTH = 80
const HEIGHT = 80
const CELL_SIZE = Size(5, 5)
const DEBUG = true


# TODO: replace with more abstract logic
function change_state!(space::Space, element::Element, state::State)::Nothing
    new_node = SpaceNode(element.node.current,
                         Properties(state),
                         space.turn)

    # @code_warntype
    set_node!(space, element.space_index, new_node)

    return
end


# TODO: choose better name?
# TODO: specify inheritance?
function Spaces.check(element::Element, parameters::Fraction)
    return rand(Float32) < parameters.border
end


# TODO: specify inheritance?
function Spaces.check(element::Element, parameters::State)
    return element.node.current.state == parameters
end


##########
# generate
##########

function process(turns::Int64, debug::Bool)

    ############
    # recorders
    ############

    drawer = SquareGreedImageRecorder(CELL_SIZE, convert(Int32, 100))

    add_biome(drawer, Biome(ALIVE, Sprite(RGB(1, 1, 1), CELL_SIZE)))
    add_biome(drawer, Biome(DEAD, Sprite(RGB(0, 0, 0), CELL_SIZE)))
    # add_biome(drawer, Biome(All(), Sprite(RGB(1, 0, 0), CELL_SIZE)))

    turns_logger = TurnsLoggerRecorder(0, TURNS + 2)

    if debug
        recorders = Recorder[]
    else
        recorders = [drawer, turns_logger]
    end

    ###########
    # generator
    ###########

    topology = SquareGreedTopology(WIDTH, HEIGHT)

    base_property = Properties(DEAD)
    space_size = WIDTH * HEIGHT

    space = LinearSpace(base_property, space_size, recorders)

    # todo: all filters must be updated on topology update
    #       better to check topology version on each filter call?
    all = All(space, topology)
    neighbors = Neighbors(space, topology)

    all() do element
        # TODO: construct Fraction(0.2) only once
        # TODO: move Fraction up
        if element |> Fraction(0.2)
            change_state!(space, element, ALIVE)  # TODO: rewrite for macros or smth else
        end
    end

    for i in 1:turns
        all() do element

            if (element |> ALIVE &&
                element |> neighbors |> ALIVE |> count ∉ 2:3)
                change_state!(space, element, DEAD)
            end

            if (element |> DEAD &&
                element |> neighbors |> ALIVE |> count == 3)
                change_state!(space, element, ALIVE)
            end

            release_all!(neighbors.cache)

        end
    end


    if !debug
        save_image(drawer, "output.gif")
    end

    println("processed")
end


@time process(TURNS, DEBUG)
