module GreedImages


using Images, Reel

using ...PCG.Geometry
using ...PCG.Types
using ...PCG.Universes

export Sprite, GreedImageRecorder, node_position, canvas_size, choose_sprite


const Image = Array{RGB{Normed{UInt8,8}}, 2}

struct Sprite
    color::RGBA
    _image::Image
end


struct GreedImageRecorder <: Recorder
    cell_size::Size{Int64}
    duration::Int64
    filename::String

    _frames::Vector{Image}
end


GreedImageRecorder(cell_size, duration, filename) = GreedImageRecorder(cell_size,
                                                                       duration,
                                                                       filename,
                                                                       [])


function node_position end
function canvas_size end
function choose_sprite end


function Universes.record_state!(universe::Universe, recorder::GreedImageRecorder)

    image_size = canvas_size(universe.topology, recorder)

    canvas = fill(RGBA(0, 0, 0, 1), yx(image_size))

    universe(complete_turn=false) do element
        sprite = choose_sprite(recorder, element)

        position = node_position(recorder, element.topology_index, image_size)

        image = sprite._image

        sprite_size = size(image)

        x = position.x
        y = position.y

        for i=y:(y+sprite_size[1]-1), j=x:(x+sprite_size[2]-1)
            canvas[i, j] += image[i-y+1, j-x+1]
        end

    end

    push!(recorder._frames, canvas)
end


function Universes.finish_recording!(recorder::GreedImageRecorder)
    # TODO: specify fps directly?
    frames = Frames(MIME("image/png"), fps=1.0 / (recorder.duration / 1000))

    # TODO: rewrite to dot syntax
    for frame in recorder._frames
        push!(frames, frame)
    end

    write(recorder.filename, frames)

end


end
