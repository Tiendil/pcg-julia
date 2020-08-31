module PCG

include("types.jl")
import .Types

include("geometry.jl")
import .Geometry

include("spaces.jl")
import .Spaces

include("topologies.jl")
import .Topologies

include("square_greed.jl")
import .SquareGreed

include("recorders/Recorders.jl")
import .Recorders

end
