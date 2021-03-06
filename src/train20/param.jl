export param, param0
using AutoGrad: Param
using Knet: atype

"""
    param(array; atype)
    param(dims...; init, atype)
    param0(dims...; atype)

The first form returns `Param(atype(array))`.

The second form Returns a randomly initialized `Param(atype(init(dims...)))`.  

The third form `param0` is an alias for `param(dims...; init=zeros)`.

By default, `init` is `xavier_uniform` and `atype` is `Knet.atype()`.

"""
param,param0

# TODO: Knet.Param <: AutoGrad.Tracked as a separate type?
param(x::AbstractArray; atype=atype()) = Param(convert(atype,x))
param(d...; init=xavier_uniform, atype=atype())=Param(atype(init(d...)))
param0(d...; atype=atype())=param(d...; init=zeros, atype=atype)
