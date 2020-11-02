
using Random

using Images

using PCG.Types
using PCG.Geometry
using PCG.Storages
using PCG.Universes
using PCG.Topologies
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

    amount = min(amount, get_node(from).new.static_water.value)

    to << (dynamic_water=Water(get_node(to).new.dynamic_water.value + amount),)
    from << (static_water=Water(get_node(from).new.static_water.value - amount),)
end


function pressure(from, to)
    return from.current.static_water.value - to.current.static_water.value
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

            e = get_node(element)

            if e.current.static_water.value == 0
                return
            end

            pressure_top, pressure_bottom, pressure_left, pressure_right = 0, 0, 0, 0

            for neighbor in element |> manhattan()

                if !isenabled(neighbor)
                    continue
                end

                n = get_node(neighbor)

                if element.topology_index.y == neighbor.topology_index.y
                    if element.topology_index.x < neighbor.topology_index.x
                        pressure_right += pressure(e, n)
                    else
                        pressure_left += pressure(e, n)
                    end

                # TODO: contrintuitive Y direction, refactoring required
                elseif element.topology_index.y < neighbor.topology_index.y
                    # ELEMENT on top of NEIGHBOR
                    if e.current.static_water.value == 0
                        if n.current.static_water.value <= BORDER
                            pressure_bottom = 0
                        else
                            pressure_bottom = BORDER - e.current.static_water.value
                        end
                    else
                        if n.current.static_water.value < BORDER
                            pressure_bottom = e.current.static_water.value
                        else
                            pressure_bottom = e.current.static_water.value - (n.current.static_water.value - BORDER)
                        end
                    end

                    # gravitation
                    pressure_bottom += e.current.static_water.value
                else
                    # ELEMENT on bottom of NEIGHBOR
                    if e.current.static_water.value <= BORDER
                        pressure_top = 0
                    else
                         pressure_top = BORDER - e.current.static_water.value
                    end
                end
            end

            # add rand to randomize sorting order in case two or more preassures are equal
            directions = [(pressure_top, rand(), 1),
                          (pressure_bottom, rand(), 2),
                          (pressure_left, rand(), 3),
                          (pressure_right, rand(), 4)]

            sort!(directions, rev=true)

            if directions[1][1] <= 0
                return
            end

            direction = directions[1][3]

            if direction == 1
                coordinates_to_flow = element.topology_index + SquareGreedIndex(0, -1)
            elseif direction == 2
                coordinates_to_flow = element.topology_index + SquareGreedIndex(0, 1)
            elseif direction == 3
                coordinates_to_flow = element.topology_index + SquareGreedIndex(-1, 0)
            else
                coordinates_to_flow = element.topology_index + SquareGreedIndex(1, 0)
            end

            if !is_valid(universe.topology, coordinates_to_flow)
                return
            end

            node_to_flow = Element(universe, coordinates_to_flow)

            flow(element, node_to_flow, 1)
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
