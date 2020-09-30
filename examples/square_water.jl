
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


const WIDTH = 20
const HEIGHT = 20
const CELL_SIZE = Size(20, 20)
const BORDER = 10
const TURNS = 1000
const DURATION = 1000
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
const WATER_SPRITES = [SquareSprite(RGB(0, 0, i / BORDER), CELL_SIZE) for i in 1:BORDER]
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


function flow(from, to, amount=1)
    to << (water=Water(to.properties.water.value + amount),)
    from << (water=Water(from.properties.water.value - amount),)
end


function process(universe::Universe, turns::Int64)

    manhattan = Neighborhood(universe.topology, manhattan_distance)

    universe(turns=turns) do element

        println("??? $(element.topology_index)")

        if element |> WALL |> exists
            return
        end

        if element |> WATER_SOURCE |> exists
            element << (water=Water(BORDER),)
        end

        element = element |> new

        for neighbor in (element |> manhattan() |> new)
            if !isenabled(neighbor)
                continue

            elseif neighbor.properties.water == element.properties.water
                continue

            # # TODO: contrintuitive Y direction, refactoring required
            # elseif neighbor.topology_index.y > element.topology_index.y
            #     if 1 < element.properties.water.value && neighbor.properties.water.value < BORDER
            #         neighbor << (water=Water(neighbor.properties.water.value + 1),)
            #         element << (water=Water(element.properties.water.value - 1),)
            #     end

            # # TODO: contrintuitive Y direction, refactoring required
            # elseif neighbor.topology_index.y < element.topology_index.y
            #     if 1 < neighbor.properties.water.value && element.properties.water.value < BORDER
            #         neighbor << (water=Water(neighbor.properties.water.value - 1),)
            #         element << (water=Water(element.properties.water.value + 1),)
            #     end

            elseif neighbor.topology_index.y == element.topology_index.y
                if neighbor.properties.water.value < element.properties.water.value
                    println("!!!", element.topology_index, "->", neighbor.topology_index)
                    flow(element, neighbor, 1)

                # elseif element.properties.water.value < neighbor.properties.water.value
                #     flow(neighbor, element, 1)
                end
            end
        end

    end
end


topology = SquareGreedTopology(WIDTH, HEIGHT)

universe = initialize(topology,
                      Properties(EMPTY, Water(0)),
                      DEBUG ? Recorder[] : [TurnsLoggerRecorder(),
                                            GreedImageRecorder(CELL_SIZE, DURATION, "output.gif")])

prepair(universe)

# precompile
@time process(universe, 1)

@time process(universe, TURNS)

finish_recording!(universe)
