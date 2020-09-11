
using Images

using PCG.Types
using PCG.Geometry
using PCG.Universes
using PCG.Topologies.SquareGreedTopologies
using PCG.Recorders.GreedImages
using PCG.Recorders.SquareGreedImages
using PCG.Recorders.TurnsLogger
using PCG.Operations
using PCG.Spaces


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


struct Properties
    state::State
end


const SPRITE_ALIVE_CELL = SquareSprite(RGB(1, 1, 1), CELL_SIZE)
const SPRITE_DEAD_CELL = SquareSprite(RGB(0, 0, 0), CELL_SIZE)


function GreedImages.choose_sprite(recorder::GreedImageRecorder, element)
    if element |> ALIVE
        return SPRITE_ALIVE_CELL
    end

    # in case of dead cell
    return SPRITE_DEAD_CELL
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


topology = SquareGreedTopology(WIDTH, HEIGHT)

universe = initialize(topology,
                      Properties(DEAD),
                      DEBUG ? Recorder[] : [TurnsLoggerRecorder(),
                                            GreedImageRecorder(CELL_SIZE, 100, "output.gif")])

# precompile
@time process(universe, 1)

@time process(universe, TURNS)

finish_recording!(universe)
