
using Random

using Images

using PCG.Types
using PCG.Geometry
using PCG.Storages
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
const BORDER = 5
const TURNS = 1000
const DURATION = 100
const DEBUG = false


struct CellType <: Checkable
    value::Int64
end

const EMPTY = CellType(1)
const WALL = CellType(2)
const WATER_SOURCE = CellType(3)


struct Water <: Checkable
    value::Int64

    # TODO: unkomment?
    # function Water(value::Int64)
    #     if 0 <= value <= BORDER
    #         return new(value)
    #     end

    #     error("water amount $(value) not in borders [0, $BORDER]")
    # end
end


struct Properties <: AbstractProperties
    type::CellType
    static_water::Water
    dynamic_water::Water
end


function Operations.check_properties(properties::Properties, parameters::CellType)
    return properties.type == parameters
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

    water_amount = get_node(element).current.static_water.value

    if water_amount == 0
        return NO_WATER_SPITE
    end

    # TODO: remove?
    if water_amount > BORDER
        return WATER_SPRITES[BORDER]
    end

    return WATER_SPRITES[water_amount]
end


function prepair(universe::Universe)
    element = Element(universe, SquareGreedIndex(WIDTH ÷ 2, 5))
    element << (type=WATER_SOURCE,)

    complete_turn!(universe)
end


function flow(from, to, amount=1)
    if amount < 0
        error("amount must be greate than zero")
    end

    to << (dynamic_water=Water(get_node(to).new.dynamic_water.value + amount),)
    from << (static_water=Water(get_node(from).new.static_water.value - amount),)
end


function process(universe::Universe, turns::Int64)

    manhattan = Neighborhood(universe.topology, manhattan_distance)

    for i in 1:turns
        universe(complete_turn=false) do element

            if element |> WALL |> exists
                return
            end

            if element |> WATER_SOURCE |> exists
                element << (static_water=Water(BORDER),
                            dynamic_water=Water(BORDER))
            end

            for neighbor in (element |> manhattan() |> shuffle!)

                if !isenabled(neighbor)
                    continue
                end

                e = get_node(element)
                n = get_node(neighbor)

                if n.current.static_water == e.new.static_water
                    continue

                # TODO: contrintuitive Y direction, refactoring required
                elseif neighbor.topology_index.y > element.topology_index.y
                    if 1 < e.new.static_water.value && n.current.static_water.value < BORDER
                        flow(element, neighbor, 1)
                    end

                elseif neighbor.topology_index.y == element.topology_index.y
                    if n.current.static_water.value < e.new.static_water.value
                        flow(element, neighbor, 1)
                    end
                end
            end
        end

        universe() do element
            if element |> EMPTY |> exists
                node = get_node(element)
                element << (static_water=Water(node.new.static_water.value + node.new.dynamic_water.value),
                            dynamic_water=Water(0))
            end
        end
    end
end


topology = SquareGreedTopology(WIDTH, HEIGHT)

universe = initialize(topology,
                      Properties(EMPTY, Water(0), Water(0)),
                      DEBUG ? Recorder[] : [TurnsLoggerRecorder(),
                                            GreedImageRecorder(CELL_SIZE, DURATION, "output.gif")])

prepair(universe)

# precompile
@time process(universe, 1)

@time process(universe, TURNS)

finish_recording!(universe)
