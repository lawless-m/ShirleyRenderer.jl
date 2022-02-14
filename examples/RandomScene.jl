using ShirleyRayTracer
using Pipe

function add_random_scene!(render::Render)

	add!(render, Sphere(Point3(0,-1000,0), 1000, Lambertian(Grey(0.5))))

	rand_material(p) = if p < 0.8 
				Lambertian()
			elseif p < 0.95
				rf = randf(0.5, 1)
				Metal(Grey(rf), 0.5rand())
			else
				Dielectric(1.5)
			end

	for a in -11:10, b in -11:10
		center = Point3(a + 0.9rand(), 0.2, b + 0.9rand())
		if ShirleyRayTracer.magnitude(center - Point3(4, 0.2, 0)) > 0.9
			add!(render, Sphere(center, 0.2, rand_material(rand())))
		end
	end

	add!(render, Sphere(Point3(0, 1, 0), 1.0, Dielectric(1.5)))
	add!(render, Sphere(Point3(-4, 1, 0), 1.0, Lambertian(Color(0.4,0.2,0.1))))
	add!(render, Sphere(Point3(4, 1, 0), 1.0, Metal(Color(0.7,0.6,0.5), 0.0)))
	render
end

function main(;filename="render.jpg", width=1200, aspect=16/9, samples=10, depth=50)

	cam = Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, aspect, 0.1, 10.0)
	@time @pipe Render(Scene(cam), width, round(Int, width / aspect), samples, depth) |>
		add_random_scene! |>
		trace |>
		save(filename, _)
end
