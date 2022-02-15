module HerbSWIPL

using Base: UInt16, String
using Julog

include("structs.jl")
include("swipl_bindings.jl")
include("swipl_interface.jl")

export Swipl 
export start, stop, cleanup, is_initialised, asserta, assertz, retract, resolve, swipl_resolve, register_foreign

end # module
