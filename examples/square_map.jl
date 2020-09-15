
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


const WIDTH = 80
const HEIGHT = 80
const CELL_SIZE = Size(10, 10)
const DEBUG = false


struct Terrain <: Checkable
    value::Int64
end


function Operations.check(element::Element, parameters::Terrain)
    return element.properties.terrain == parameters
end


const GRASS = Terrain(1)
const WATER = Terrain(2)
const SAND = Terrain(3)
const FOREST = Terrain(4)


struct Properties <: AbstractProperties
    terrain::Terrain
end


const SPRITE_GRASS = SquareSprite(RGB(0, 1, 0), CELL_SIZE)
const SPRITE_WATER = SquareSprite(RGB(0, 0, 1), CELL_SIZE)
const SPRITE_SAND = SquareSprite(RGB(1, 1, 0), CELL_SIZE)
const SPRITE_FOREST = SquareSprite(RGB(0, 0.5, 0), CELL_SIZE)
const SPRITE_ERROR = SquareSprite(RGB(1, 0, 0), CELL_SIZE)


function GreedImages.choose_sprite(recorder::GreedImageRecorder, element)
    if element |> GRASS |> exists
        return SPRITE_GRASS
    end

    if element |> WATER |> exists
        return SPRITE_WATER
    end

    if element |> SAND |> exists
        return SPRITE_SAND
    end

    if element |> FOREST |> exists
        return SPRITE_FOREST
    end

    return SPRITE_ERROR
end


function process(universe::Universe)

    ring = Neighborhood(universe.topology, ring_distance)
    euclidean = Neighborhood(universe.topology, euclidean_distance)

    complete_turn!(universe)

    universe() do element
        if element |> Fraction(0.01) |> exists
            element << (terrain=WATER,)
        end
    end

    universe() do element
        if element |> Fraction(0.8) |> GRASS |> euclidean(1, 3) |> WATER |> exists
            element << (terrain=WATER,)
        end
    end

    universe() do element
        if element |> GRASS |> ring() |> WATER |> exists
            element << (terrain=SAND,)
        end
    end

    universe(turns=3) do element
        if element |> Fraction(0.1) |> GRASS |> ring() |> SAND |> exists
            element << (terrain=SAND,)
        end
    end

    universe(turns=4) do element
        if element |> SAND |> ring() |> WATER |> count >= 6
            element << (terrain=WATER,)
        end
    end

    universe() do element
        if element |> GRASS |> Fraction(0.03) |> exists
            element << (terrain=FOREST,)
        end
    end

    universe() do element
        if (element |> GRASS |> Fraction(0.1) |> exists &&
            element |> ring(2, 2) |> FOREST |> exists &&
            element |> ring() |> new |> FOREST |> not_exists)

            element << (terrain=FOREST,)
        end
    end

end


topology = SquareGreedTopology(WIDTH, HEIGHT)

universe = initialize(topology,
                      Properties(GRASS),
                      DEBUG ? Recorder[] : [TurnsLoggerRecorder(),
                                            GreedImageRecorder(CELL_SIZE, 1000, "output.gif")])

@time process(universe)

finish_recording!(universe)
