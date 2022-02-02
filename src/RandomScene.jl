using ShirleyRayTracer

#==

# launch using 40 threads
 julia -t 40 --project=.. -L RandomScene.jl  -e "main()" > random_scene.ppm

# launch force using 1 thread
 julia -t 1 --project=.. -L RandomScene.jl  -e "main()" > random_scene.ppm

# launch using thread count from environment
 julia --project=.. -L RandomScene.jl  -e "main()" > random_scene.ppm

==#

function add_random_scene!(scene::Scene) 

	add!(scene, Sphere(Point3(0,-1000,0), 1000, Lambertian(Color(0.5, 0.5, 0.5))))

	rand_material(p) = if p < 0.8 
				Lambertian()
			elseif p < 0.95
				rf = randf(0.5, 1)
				Metal(Color(rf, rf, rf), 0.5rand())
			else
				Dielectric(1.5)
			end

	for a in -11:10, b in -11:10
		center = Point3(a + 0.9rand(), 0.2, b + 0.9rand())
		if magnitude(center - Point3(4, 0.2, 0)) > 0.9
			add!(scene, Sphere(center, 0.2, rand_material(rand())))
		end
	end

	add!(scene, Sphere(Point3(0, 1, 0), 1.0, Dielectric(1.5)))
	add!(scene, Sphere(Point3(-4, 1, 0), 1.0, Lambertian(0.4,0.2,0.1)))
	add!(scene, Sphere(Point3(4, 1, 0), 1.0, Metal(Color(0.7,0.6,0.5), 0.0)))
end

function main(;filename="", image_width=1200, aspect_ratio=16/9, samples_per_pixel=10, max_depth=50)
	image_height = round(Int, image_width / aspect_ratio)
	world = Scene(Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, aspect_ratio, 0.1, 10.0))
	add_random_scene!(world)
    scanlines = render(world, image_width, image_height, samples_per_pixel, max_depth)
    if filename == ""
        write_ppm(stdout, scanlines)
    else
        open(filename, "w") do io
            write_ppm(io, scanlines)
        end
    end
end

