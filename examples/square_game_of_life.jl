
using InteractiveUtils

using Images

using PCG
using PCG.Geometry
using PCG.Topologies
using PCG.Topologies.SquareGreedTopologies
using PCG.Recorders.SquareGreedImage
using PCG.Recorders.TurnsLogger
using PCG.Storages
using PCG.Storages.LinearStorages
using PCG.Universes
using PCG.Operations

using PCG.Types


const WIDTH = 80
const HEIGHT = 80
const CELL_SIZE = Size(5, 5)
const TURNS = 100
const DEBUG = false


struct State <: Checkable
    value::Int64
end

function Operations.check(element::Element, parameters::State)
    return element.node.current.state == parameters
end


const DEAD = State(1)
const ALIVE = State(2)


# TODO: specify parent class
struct Properties
    state::State
end


const SPRITE_ALIVE_CELL = Sprite(RGB(1, 1, 1), CELL_SIZE)
const SPRITE_DEAD_CELL = Sprite(RGB(0, 0, 0), CELL_SIZE)


# TODO: does that is correct way to specify function for object?
#       probably note
function SquareGreedImage.choose_sprite(recorder::SquareGreedImageRecorder, element)
    if element |> ALIVE
        return SPRITE_ALIVE_CELL
    end

    # in case of dead cell
    return SPRITE_DEAD_CELL
end


function initialize()
    drawer = SquareGreedImageRecorder(CELL_SIZE, convert(Int32, 100), "output.gif")

    turns_logger = TurnsLoggerRecorder(TURNS + 1)

    if DEBUG
        recorders = Recorder[]
    else
        recorders = [drawer, turns_logger]
    end

    topology = SquareGreedTopology(WIDTH, HEIGHT)

    storage = LinearStorage(Properties(DEAD), WIDTH * HEIGHT)

    universe = Universe(storage, topology, recorders)

    universe.cache = AreaCache{typeof(universe),
                               SquareGreedIndex,
                               LinearStorageIndex,
                               StorageNode{Properties}}()

    return universe
end


function process(universe::Universe, turns::Int64)

    neighbors = SquareGreedNeighborhood()

    universe() do element
        if element |> Fraction(0.2)
            element << (state=ALIVE,)
        end
    end

    for i in 1:turns
        universe() do element

            if (element |> ALIVE &&
                element |> neighbors |> ALIVE |> count ∉ 2:3)
                element << (state=DEAD,)
            end

            if (element |> DEAD &&
                element |> neighbors |> ALIVE |> count == 3)
                element << (state=ALIVE,)
            end

        end
    end

end


universe = initialize()

# precompile
@time process(universe, 1)

@time process(universe, TURNS)

finish_recording!(universe)
