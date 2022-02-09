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
OneWeekend branch is now 

```
matt:~/GitHub/ShirleyRenderer.jl$ time julia --project=. -t 1 -L examples/RandomScene.jl -e "@time main()"
 61.614893 seconds (9.18 M allocations: 360.314 MiB, 0.58% gc time, 3.23% compilation time)

real	1m9.593s
user	1m8.392s
sys	0m0.933s
```

Multi threaded

```
matt:~/GitHub/ShirleyRenderer.jl$ time julia --project=. -t 20 -L examples/RandomScene.jl -e "@time main()"
  6.947836 seconds (9.18 M allocations: 360.450 MiB, 2.51% gc time, 31.47% compilation time)

real	0m15.169s
user	1m40.759s
sys	0m1.076s
```
