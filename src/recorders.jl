module Recorders

using Images, Reel

using ..PCG.Geometry: Size

export Sprite, Biome, Recorder, add_biome, save_image

struct Sprite
    color::Any
    _image::Any
end


Sprite(color, cell_size::Size) = Sprite(color, fill(color, (Int64(cell_size.y), Int64(cell_size.x))))


struct Biome
    checker::Any
    sprite::Sprite
end


mutable struct Recorder
    cell_size::Size
    duration::Int32
    filename::String

    _biomes::Array{Biome, 1}
    _frames::Array{Any, 1}
end

Recorder(cell_size::Size, duration::Int32, filename::String) = Recorder(cell_size,
                                                                        duration,
                                                                        filename,
                                                                        [],
                                                                        [])



function add_biome(drawer::Recorder, biome::Biome)
    push!(drawer._biomes, biome)
end


function save_image(drawer::Recorder, filename::String)

    frames = Frames(MIME("image/png"), fps=1.0 / (drawer.duration / 1000))

    # TODO: rewrite to dot syntax
    for frame in drawer._frames
        push!(frames, frame)
    end

    write(filename, frames)
end


end
