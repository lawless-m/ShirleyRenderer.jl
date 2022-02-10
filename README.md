# ShirleyRayTracer

port of the C++ code on

https://github.com/RayTracing/raytracing.github.io

C++ runs in ~50s

This branch now runs in ~70s for TTFX

~60s for Second render

```
matt@pox:~/GitHub/ShirleyRenderer.jl$ time julia --project=. -t 1 -L examples/RandomScene.jl -e "@time main()"
 64.737416 seconds (7.87 M allocations: 311.747 MiB, 0.22% gc time, 2.57% compilation time)

real    1m12.943s
user    1m11.591s
sys     0m1.083s

$> julia -q --project=. -t 1
julia> include("examples/RandomScene.jl")

julia> @time main()
 64.341958 seconds (3.65 M allocations: 84.564 MiB, 0.07% gc time, 0.35% compilation time)
 
julia> @benchmark main()
BenchmarkTools.Trial: 1 sample with 1 evaluation.
 Single result which took 62.764 s (0.02% GC) to evaluate,
 with a memory estimate of 61.97 MiB, over 3247747 allocations.

```

With 40 threads ~15s for TTFX and 3.7s for a hot render

```
matt@pox:~/GitHub/ShirleyRenderer.jl$ time julia --project=. -t 40 -L examples/RandomScene.jl -e "@time main()"
  5.902854 seconds (7.88 M allocations: 311.993 MiB, 1.76% gc time, 33.88% compilation time)

real    0m14.219s
user    2m57.157s
sys     0m1.023s

$> julia -q --project=. -t 40
julia> include("examples/RandomScene.jl")

julia> @time main()
  5.616959 seconds (7.60 M allocations: 296.944 MiB, 1.99% gc time, 31.26% compilation time)

julia> @benchmark main()
BenchmarkTools.Trial: 2 samples with 1 evaluation.
 Range (min … max):  3.586 s …    3.730 s  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     3.658 s               ┊ GC (median):    0.00%
 Time  (mean ± σ):   3.658 s ± 102.103 ms  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █                                                        █  
  █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█ ▁
  3.59 s         Histogram: frequency by time         3.73 s <

 Memory estimate: 61.99 MiB, allocs estimate: 3247946.

```
