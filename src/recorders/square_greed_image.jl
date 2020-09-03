module SquareGreedImage

using Images, Reel

using ...PCG.Geometry: Size, Point
using ...PCG.Types: Recorder
using ...PCG.Spaces
using ...PCG.Spaces.LinearSpaces
using ...PCG.Topologies
using ...PCG.Topologies.SquareGreedTopologies


export Sprite, Biome, SquareGreedImageRecorder, add_biome, save_image

struct Sprite
    color::Any
    _image::Any
end


Sprite(color, cell_size::Size) = Sprite(color, fill(color, (Int64(cell_size.y), Int64(cell_size.x))))


struct Biome
    checker::Any
    sprite::Sprite
end


mutable struct SquareGreedImageRecorder <: Recorder
    cell_size::Size
    duration::Int32

    _biomes::Array{Biome, 1}
    _frames::Array{Any, 1}
end


SquareGreedImageRecorder(cell_size::Size, duration::Int32) = SquareGreedImageRecorder(cell_size,
                                                                                      duration,
                                                                                      [],
                                                                                      [])



function add_biome(drawer::SquareGreedImageRecorder, biome::Biome)
    push!(drawer._biomes, biome)
end


function save_image(drawer::SquareGreedImageRecorder, filename::String)

    frames = Frames(MIME("image/png"), fps=1.0 / (drawer.duration / 1000))

    # TODO: rewrite to dot syntax
    for frame in drawer._frames
        push!(frames, frame)
    end

    write(filename, frames)
end


function node_position(recorder::SquareGreedImageRecorder, index::SquareGreedIndex, canvas_size::Point)
    # TODO: is it right?
    return (Point(index) - Point(1.0, 1.0)) * recorder.cell_size
end


###########################################################
# TODO: that code duplicates "all" prdicate from examples

function to_index(topology::Topology, i::SquareGreedIndex)
    return LinearSpaceIndex((i.y - 1) * topology.height + i.x)
end

function all(space::Space, topology::Topology)
    return ((i, get_node(space, to_index(topology, i)))
            for i in nodes_coordinates(topology))
end

#
############################################################


function Spaces.record_state!(space::Space, topology::Topology, recorder::SquareGreedImageRecorder)

    #TODO: rewrite
    canvas_size = ceil(Point(topology.width, topology.height) * recorder.cell_size)

    # TODO: fill with monotone color (use zeros? https://docs.julialang.org/en/v1/base/arrays/#Base.zeros)
    canvas = rand(RGB, Int64(canvas_size.y), Int64(canvas_size.x))

    for (index, node) in all(space, topology)
        biome = choose_biome(recorder, node)

        position = node_position(recorder, index, canvas_size)

        image = biome.sprite._image

        # TODO: move out?
        sprite_size = size(image)

        x = Int64(position.x) + 1
        y = Int64(position.y) + 1

        # TODO: round position correctly
        # TODO: replace with coping to slice
        copyto!(canvas,
                # TODO: does indexes places right?
                # TODO: fix size calculation
                CartesianIndices((x:(x+sprite_size[1]-1), y:(y+sprite_size[2]-1))),
                image,
                CartesianIndices((1:sprite_size[1], 1:sprite_size[2])))
    end

    push!(recorder._frames, canvas)
end


function choose_biome(drawer::SquareGreedImageRecorder, node::SpaceNode)
    for biome in drawer._biomes
        if check(node, biome.checker)
            return biome
        end
    end
end


end
