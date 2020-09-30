
using Images

using PCG.Types
using PCG.Geometry
using PCG.Universes
using PCG.Topologies.SquareGreedTopologies
using PCG.Neighborhoods
using PCG.Operations
using PCG.Spaces
using PCG.Recorders.GreedImages
using PCG.Recorders.SquareGreedImages
using PCG.Recorders.TurnsLogger


const WIDTH = 150
const HEIGHT = 150
const CELL_SIZE = Size(5, 5)
const BORDER = 100
const TURNS = 100
const DEBUG = false


struct CellType <: Checkable
    value::Int64
end

const EMPTY = CellType(1)
const WALL = CellType(2)
const WATER_SOURCE = CellType(3)


function Operations.check(element::Element, parameters::CellType)
    return element.properties.type == parameters
end


struct Water <: Checkable
    value::Int64

    function Water(value::Int64)
        if 0 <= value <= BORDER
            return new(value)
        end

        error("water amount $(value) not in borders [0, $BORDER]")
    end
end


# function Operations.check(element::Element, parameters::State)
#     return element.properties.state == parameters
# end


struct Properties <: AbstractProperties
    type::CellType
    water::Water
end


const WALL_SPITE = SquareSprite(RGB(1, 1, 0), CELL_SIZE)
const WATER_SOURCE_SPRITE = SquareSprite(RGB(1, 0, 0), CELL_SIZE)
const WATER_SPRITES = [SquareSprite(RGB(0, 0, i / 100), CELL_SIZE) for i in 1:100]
const NO_WATER_SPITE = SquareSprite(RGB(0, 0, 0), CELL_SIZE)


function GreedImages.choose_sprite(recorder::GreedImageRecorder, element)
    if element |> WALL |> exists
        return WALL_SPITE
    end

    if element |> WATER_SOURCE |> exists
        return WATER_SOURCE_SPRITE
    end

    water_amount = element.properties.water.value

    if water_amount == 0
        return NO_WATER_SPITE
    end

    return WATER_SPRITES[water_amount]
end


function prepair(universe::Universe)
    element = Element(universe, SquareGreedIndex(WIDTH // 2, 5))
    element << (type=WATER_SOURCE,)
end


function process(universe::Universe, turns::Int64)

    manhattan = Neighborhood(universe.topology, manhattan_distance)

    universe(turns=turns) do element

        if element |> WATER_SOURCE |> exists
            element << (water=Water(BORDER),)
            return
        end

        for neighbor in (element |> manhattan())
            if !neighbor.enabled
                continue

            elseif neighbor.properties.water == element.properties.water
                continue

            elseif neighbor.topology_index.y == element.topology_index.y
                if neighbor.properties.water.value < element.properties.water.value
                    neighbor << (water=Water(neighbor.properties.water.value + 1),)
                    element << (water=Water(element.properties.water.value - 1),)
                else
                    neighbor << (water=Water(neighbor.properties.water.value - 1),)
                    element << (water=Water(element.properties.water.value + 1),)
                end

            elseif neighbor.topology_index.y < element.topology_index.y
                if neighbor.properties.water.value < element.properties.water.value
                    neighbor << (water=Water(neighbor.properties.water.value + 1),)
                    element << (water=Water(element.properties.water.value - 1),)
                end
            end
        end

    end
end


topology = SquareGreedTopology(WIDTH, HEIGHT)

universe = initialize(topology,
                      Properties(EMPTY, Water(0)),
                      DEBUG ? Recorder[] : [TurnsLoggerRecorder(),
                                            GreedImageRecorder(CELL_SIZE, 100, "output.gif")])

prepair(universe)

# precompile
@time process(universe, 1)

@time process(universe, TURNS)

finish_recording!(universe)
