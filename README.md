# ShirleyRayTracer

port of the C++ code on

https://github.com/RayTracing/raytracing.github.io

C++ runs in ~50s

This branch now runs in 1m9s for TTFX

~60s for Second render

```
$> julia -q --project=. -t 1
julia> include("examples/RandomScene.jl")

julia> @time main()
 64.417148 seconds (8.88 M allocations: 343.991 MiB, 0.30% gc time, 2.65% compilation time)

julia> @benchmark main()
BenchmarkTools.Trial: 1 sample with 1 evaluation.
 Single result which took 59.794 s (0.03% GC) to evaluate,
 with a memory estimate of 82.07 MiB, over 4057748 allocations.

```

With 40 threads ~15s for TTFX and 3.7s for a hot render

```
$> julia -q --project=. -t 40
julia> include("examples/RandomScene.jl")

julia> @time main()
  6.066820 seconds (8.88 M allocations: 344.228 MiB, 6.22% gc time, 35.41% compilation time)

julia> @benchmark main()
BenchmarkTools.Trial: 2 samples with 1 evaluation.
 Range (min … max):  3.736 s …   3.763 s  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     3.750 s              ┊ GC (median):    0.00%
 Time  (mean ± σ):   3.750 s ± 19.139 ms  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █                                                       █  
  █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█ ▁
  3.74 s         Histogram: frequency by time        3.76 s <

 Memory estimate: 82.09 MiB, allocs estimate: 4057949.

```
