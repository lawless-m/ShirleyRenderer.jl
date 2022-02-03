# ShirleyRayTracer

port of the C++ code on - https://github.com/RayTracing/raytracing.github.io

Runs the Week1 scene in 1m15s, compared to the 49s for the C++ version, with much room for improvement - too many allocations

Also supports threads so with -t 20 it completes in 
```
matt:~/GitHub/ShirleyRenderer.jl$ time julia -t 20 --project=. -L src/RandomScene.jl  -e "@time main()"
  8.314338 seconds (6.37 M allocations: 314.804 MiB, 2.23% gc time, 23.71% compilation time)

real    0m16.360s
user    1m58.585s
sys     0m1.036s
```
