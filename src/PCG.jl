module PCG

include("types.jl")
import .Types

include("geometry.jl")
import .Geometry

include("spaces/Spaces.jl")
import .Spaces

include("topologies/Topologies.jl")
import .Topologies

# include("square_greed.jl")
# import .SquareGreed

include("recorders/Recorders.jl")
import .Recorders

end
