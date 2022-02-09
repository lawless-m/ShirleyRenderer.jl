using ShirleyRayTracer
using Test

function single_scancol()
    scene = Scene(Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, 16/9, 0.1, 10.0))
    add!(scene, Sphere(Point3(0, 1, 0), 1.0, Dielectric(1.5)))
	add!(scene, Sphere(Point3(-4, 1, 0), 1.0, Lambertian(Color(0.4,0.2,0.1))))
	add!(scene, Sphere(Point3(4, 1, 0), 1.0, Metal(Color(0.7,0.6,0.5), 0.0)))
    @time ShirleyRayTracer.trace_scancol(scene, 600, 1, 1200, 100, 5)
    true
end

@testset "ShirleyRayTracer.jl" begin
    @test single_scancol()
end
