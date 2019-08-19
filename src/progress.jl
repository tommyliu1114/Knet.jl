# Based on https://github.com/cloud-oak/Tqdm.jl by @cloud-oak under Mozilla Public License 2.0
# Modified for Knet by Deniz Yuret

using Printf
import Base: length, size, iterate, eltype, IteratorSize, IteratorEltype, haslength, @propagate_inbounds

"""
    progress(itr, interval=100)
    progress(itr, interval=100) do x; f(x); end
    progress(f, itr, interval=100)

Return an iterator which acts exactly like `itr`, but prints a progressbar as new values are
requested:

    ┣█████████████████▎  ┫ [86.83%, 903/1040, 01:36/01:50, 9.42i/s] 3.87835

Here `86.83%` is the percentage completed, `903` is the number of iterations completed,
`1040` is the total number of iterations. `01:36` is elapsed time, `01:50` is the estimated
total time, `9.42i/s` is the average number of iterations completed per second. If the speed
is less than 1, the average number of seconds per iteration (s/i) is reported instead.  The
bar, percent, total iterations, and estimated total time are omitted for iterators whose
size is unknown.

`3.87835` is the output of `f` applied to the last value generated by itr. If `f` is not
specified nothing gets printed.  `f` is called and progressbar is updated during the first
and last iterations and every `interval` iterations in between.

`progress!(...)` is equivalent to `(for x in progress(...) end)`, i.e.  iterates over the
object created by `progress(...)` and returns `nothing`.
"""
progress, progress!

mutable struct Progress{I}
    func
    iter::I
    interval::UInt
    nextprint::UInt
    starttime::UInt
    completed::UInt
    lastval
end

progress(func::Base.Callable, iter::I, interval::Integer=100) where {I} =
    Progress{I}(func,iter,interval,interval,0,0,nothing)

progress(iter, interval::Integer=100)=progress((x)->"",iter,interval)
progress!(x...)=(for _ in progress(x...) end)

IteratorSize(::Type{Progress{I}}) where {I} = IteratorSize(I)
IteratorEltype(::Type{Progress{I}}) where {I} = Base.EltypeUnknown()
length(p::Progress) = length(p.iter)

@propagate_inbounds function iterate(p::Progress, s...)
    if p.starttime == 0; p.starttime = time_ns(); end
    next = iterate(p.iter, s...)
    if next !== nothing
        p.completed += 1
        (p.lastval, s) = next
    elseif p.completed == 0
        return next             # don't print anything if no iterations
    end
    if 1 < p.completed < p.nextprint && next !== nothing
        return next             # only print if first, last, or nextprint
    elseif p.completed == p.nextprint
        p.nextprint += p.interval
    end
    fval_string = string(p.func(p.lastval))
    curr_time = time_ns()
    seconds   = (curr_time - p.starttime) * 1e-9
    speed     = p.completed / seconds

    if haslength(p)
        ETA = (length(p) - p.completed) / speed
        percentage_string = string(@sprintf("%.2f%%",p.completed/length(p)*100))
        status_string = string("[", percentage_string, 
                               ", ", p.completed, "/", length(p), 
                               ", ", format_time(seconds), "/", format_time(seconds+ETA), 
                               ", ", format_speed(speed),
                               "] ")
    else
        status_string = string("[", p.completed,
                               ", ", format_time(seconds),
                               ", ", format_speed(speed),
                               "] ")
    end

    print("\r")

    if (haslength(p))
        width = 20
        print("┣")
        cellvalue = length(p) / width
        full_cells, remain = divrem(p.completed, cellvalue)
        full_cells = round(Int, full_cells)
        print(repeat("█", full_cells))
        if (full_cells < width)
	    part = floor(Int, 8 * remain / cellvalue)
	    print(EIGHTS[part])
            print(repeat(" ", width - full_cells - 1))
        end
        print("┫ ")
    end

    print(status_string)
    print(fval_string)
    next === nothing && println()
    return next
end

function format_time(seconds)
    if seconds != Inf
        mins,s  = divrem(round(Int,seconds), 60)
        h, m    = divrem(mins, 60)
    else
        h=0;m=Inf;s=Inf
    end
    if h!=0
         return @sprintf("%02d:%02d:%02d",h,m,s)
    else
         return @sprintf("%02d:%02d",m,s)
    end
end

format_speed(s)=(s >= 1 ? @sprintf("%.2fi/s",s) : @sprintf("%.2fs/i",1/s))

EIGHTS = Dict(0 => ' ',
	      1 => '▏',
	      2 => '▎',
	      3 => '▍',
	      4 => '▌',
	      5 => '▋',
	      6 => '▊',
	      7 => '▉',
	      8 => '█')
