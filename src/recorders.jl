module Recorders

using Images, Reel

using ..PCG.Geometry: Size, Point
using ..PCG.Types: Recorder
using ..PCG.Spaces


export Sprite, Biome, Recorder2D, add_biome, save_image

struct Sprite
    color::Any
    _image::Any
end


Sprite(color, cell_size::Size) = Sprite(color, fill(color, (Int64(cell_size.y), Int64(cell_size.x))))


struct Biome
    checker::Any
    sprite::Sprite
end


mutable struct Recorder2D <: Recorder
    cell_size::Size
    duration::Int32
    filename::String

    _biomes::Array{Biome, 1}
    _frames::Array{Any, 1}
end


Recorder2D(cell_size::Size, duration::Int32, filename::String) = Recorder2D(cell_size,
                                                                            duration,
                                                                            filename,
                                                                            [],
                                                                            [])



function add_biome(drawer::Recorder2D, biome::Biome)
    push!(drawer._biomes, biome)
end


function save_image(drawer::Recorder2D, filename::String)

    frames = Frames(MIME("image/png"), fps=1.0 / (drawer.duration / 1000))

    # TODO: rewrite to dot syntax
    for frame in drawer._frames
        push!(frames, frame)
    end

    write(filename, frames)
end


function node_position(recorder::Recorder2D, node::Node, canvas_size::Size)
    # TODO: is it right?
    return (node.coordinates - Point(1.0, 1.0)) * recorder.cell_size
end


function Spaces.record_state(space::Space{Node}, recorder::Recorder2D)

    canvas_size = ceil(space_size(space._base_nodes) * recorder.cell_size)

    # TODO: fill with monotone color (use zeros? https://docs.julialang.org/en/v1/base/arrays/#Base.zeros)
    canvas = rand(RGB, Int64(canvas_size.y), Int64(canvas_size.x))

    for node in space._base_nodes
        biome = choose_biome(recorder, node)

        position = node_position(recorder, node, canvas_size)

        image = biome.sprite._image

        # TODO: move out?
        sprite_size = size(image)

        x = Int64(position.x) + 1
        y = Int64(position.y) + 1

        # TODO: round position correctly
        copyto!(canvas,
                # TODO: does indexes places right?
                # TODO: fix size calculation
                CartesianIndices((x:(x+sprite_size[1]-1), y:(y+sprite_size[2]-1))),
                image,
                CartesianIndices((1:sprite_size[1], 1:sprite_size[2])))
    end

    push!(recorder._frames, canvas)
end


function choose_biome(drawer::Recorder2D, node::Node)
    for biome in drawer._biomes
        if check(node, biome.checker)
            return biome
        end
    end
end


end
