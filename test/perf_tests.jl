using ShirleyRayTracer
using BenchmarkTools
using Profile

function setup()
    cam = Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, 16/9, 0.1, 10.0)
    scene = Scene(cam)
    add!(scene, Sphere(Point3(0, 1, 0), 1.0, Dielectric(1.5)))
    add!(scene, Sphere(Point3(-4, 1, 0), 1.0, Lambertian(Color(0.4,0.2,0.1))))
    add!(scene, Sphere(Point3(4, 1, 0), 1.0, Metal(Color(0.7,0.6,0.5), 0.0)))
    rec = ShirleyRayTracer.Hit()
    ray = ShirleyRayTracer.Ray()

    scene, rec, ray
end

function rc_warn()
    
    scene, rec, ray = setup()

    @time ShirleyRayTracer.reset_ray!(ray, scene, 0.5, 0.5)
   # @time ShirleyRayTracer.ray_color!(rec, ray, scene, 20)
    #@time ShirleyRayTracer.trace!(rec, scene.hitables, ray, 0.001, Inf)
    @time ShirleyRayTracer.trace!(rec, scene.hitables[3], ray, 0.001, Inf)
    println(rec)
    @time ShirleyRayTracer.emitted(rec.material, rec.u, rec.v, rec.p)
    #@time ShirleyRayTracer.scatter!(rec.material, ray, rec)

end

function prof()
    scene, rec, ray = setup()
    @profile trace_scancol(scene, 400, 1, 800, 600, 5)
end
