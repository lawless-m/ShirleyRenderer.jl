using ShirleyRayTracer
using BenchmarkTools
using Profile
using Debugger

function setup()
    scene = Scene(Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, 16/9, 0.1, 10.0), Color(0.5,0.5,0.5))
	
    add!(scene, Sphere(Point3(0, 1, 0), 1.0, add!(scene, Dielectric(1.5))))
    rec = ShirleyRayTracer.Hit()
    ray = ShirleyRayTracer.Ray()

    scene, rec, ray
end

function rc_warn()
    
    scene, rec, ray = setup()

    @code_warntype ShirleyRayTracer.reset_ray!(ray, scene, 0.5, 0.5)
    @code_warntype ShirleyRayTracer.trace!(rec, scene.hitables, ray, 0.001, Inf)
    @code_warntype ShirleyRayTracer.trace!(rec, scene.hitables[1], ray, 0.001, Inf)
    rec.material = scene.hitables[1].material
    @code_warntype ShirleyRayTracer.ray_color!(rec, ray, scene, 20)
    @code_warntype ShirleyRayTracer.emitted(rec.material, rec.u, rec.v, rec.p)
    @code_warntype ShirleyRayTracer.scatter!(rec.material, ray, rec)

end

function prof()
    scene, rec, ray = setup()
    @profile trace_scancol(scene, 400, 1, 800, 600, 5)
end

function bp_code()
    
    scene, rec, ray = setup()

    ShirleyRayTracer.reset_ray!(scene, ray, 0.5, 0.5)
    ShirleyRayTracer.trace!(scene.hitables, ray, rec, 0.001, Inf)
    ShirleyRayTracer.trace!(scene.hitables[1], ray, rec, 0.001, Inf)
    rec.material = scene.hitables[1].material
    @bp
    ShirleyRayTracer.ray_color!(scene, ray, rec, 20)
    ShirleyRayTracer.emitted(scene, rec, rec.u, rec.v, rec.p)
    ShirleyRayTracer.scatter!(scene, ray, rec)

end
