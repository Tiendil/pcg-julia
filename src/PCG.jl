module PCG

include("types.jl")
import .Types

include("arrays_caches.jl")
import .ArraysCaches

include("geometry.jl")
import .Geometry

include("topologies/Topologies.jl")
import .Topologies

include("storages/Storages.jl")
import .Storages

include("universes.jl")
import .Universes

include("neighborhoods.jl")
import .Neighborhoods

include("operations.jl")
import .Operations

include("recorders/Recorders.jl")
import .Recorders

include("spaces.jl")
import .Spaces

end
