using ShirleyRayTracer
using Test

defscene() = Scene(Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, 16/9, 0.1, 10.0), Color(0.5,0.5,0.5))

function single_scancol()
	scene = defscene()
	add!(scene, Sphere(Point3(0, 1, 0), 1.0, add!(scene, Dielectric(1.5))))
	add!(scene, Sphere(Point3(-4, 1, 0), 1.0, add!(scene, Lambertian(Color(0.4,0.2,0.1)))))
	add!(scene, Sphere(Point3(4, 1, 0), 1.0, add!(scene, Metal(Color(0.7,0.6,0.5), 0.0))))
	@time ShirleyRayTracer.trace_scancol(scene, 600, 1, 1200, 100, 5)
	true
end

@testset "ShirleyRayTracer.jl" begin
    @test single_scancol()
    begin 
        include("../examples/Scenes.jl")
        scene = defscene()
        random_scene(scene)
        @test length(scene.hitables) == 1
        empty!(scene.hitables)
        two_spheres(scene)
        @test length(scene.hitables) == 2
        empty!(scene.hitables)
        two_perlin_spheres(scene)
        @test length(scene.hitables) == 2
        empty!(scene.hitables)
        earth(scene; filename="../examples/earthmap.jpg")
        @test length(scene.hitables) == 3
        empty!(scene.hitables)
        simple_light(scene)
        @test length(scene.hitables) == 4
        empty!(scene.hitables)
        cornell_box(scene)
        @test length(scene.hitables) == 8
        empty!(scene.hitables)
        cornell_smoke(scene)
        @test length(scene.hitables) == 8
        empty!(scene.hitables)
        final_scene(scene; filename="../examples/earthmap.jpg")
        @test length(scene.hitables) == 11
    end
end
