module SquareGreedImage

using Images, Reel

using ...PCG.Geometry: Size, Point
using ...PCG.Types: Recorder
using ...PCG.Storages
using ...PCG.Storages.LinearStorages
using ...PCG.Topologies
using ...PCG.Topologies.SquareGreedTopologies
using ...PCG.Universes
using ...PCG.Universes: Universe
using ...PCG.Operations


export Sprite, Biome, SquareGreedImageRecorder, add_biome, save_image

const Image = Array{RGB{Normed{UInt8,8}}, 2}


struct Sprite
    color::RGB
    _image::Image
end


Sprite(color, cell_size::Size) = Sprite(color, fill(color, (Int64(cell_size.y), Int64(cell_size.x))))


struct SquareGreedImageRecorder <: Recorder
    cell_size::Size
    duration::Int32
    filename::String

    _frames::Vector{Image}
end


SquareGreedImageRecorder(cell_size::Size, duration::Int32, filename::String) = SquareGreedImageRecorder(cell_size,
                                                                                                        duration,
                                                                                                        filename,
                                                                                                        [])


function node_position(recorder::SquareGreedImageRecorder, index::SquareGreedIndex, canvas_size::Point)
    # TODO: is it right?
    return (Point(index) - Point(1.0, 1.0)) * recorder.cell_size
end


function choose_sprite end


function Universes.record_state!(universe::Universe, recorder::SquareGreedImageRecorder)

    #TODO: rewrite
    canvas_size = ceil(Point(universe.topology.width, universe.topology.height) * recorder.cell_size)

    canvas = Image(undef, Int64(canvas_size.y), Int64(canvas_size.x))

    universe(complete_turn=false) do element
        sprite = choose_sprite(recorder, element)

        position = node_position(recorder, element.topology_index, canvas_size)

        image = sprite._image

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


function Universes.finish_recording!(recorder::SquareGreedImageRecorder)
    # TODO: specify fps directly?
    frames = Frames(MIME("image/png"), fps=1.0 / (recorder.duration / 1000))

    # TODO: rewrite to dot syntax
    for frame in recorder._frames
        push!(frames, frame)
    end

    write(recorder.filename, frames)

end


end
