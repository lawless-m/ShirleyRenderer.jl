
@everywhere include("../src/ShirleyRayTracer.jl")
@everywhere using .ShirleyRayTracer

Colour = ShirleyRayTracer.Color

using Pipe
using Images

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
	add!(render, Sphere(Point3(-4, 1, 0), 1.0, Lambertian(Colour(0.4,0.2,0.1))))
	add!(render, Sphere(Point3(4, 1, 0), 1.0, Metal(Colour(0.7,0.6,0.5), 0.0)))
	render
end

function Dtrace(render)
        ch_x = RemoteChannel(()->Channel{Int}(length(workers())))
        ch_results = RemoteChannel(()->Channel{Tuple}(1))

        @async foreach(x->put!(ch_x, x), 1:render.width)

        for p in workers()
           remote_do(trace, p, render, ch_x, ch_results)
        end

        image = Array{Colour, 2}(undef, render.height, render.width)

        for _ in 1:render.width
                col = take!(ch_results)
                @inbounds image[:, col[1]] = col[2]
        end

        foreach(x->put!(ch_x, 0), 1:length(workers()))

        image
end



val(rgb) = isnan(rgb) ? 0 : clamp(sqrt(rgb), 0, 1)
rgbf8(rgb) = RGB{N0f8}(val(rgb[1]), val(rgb[2]), val(rgb[3]))

function main(;filename="render.jpg", width=1200, aspect=16/9, samples=10, depth=50)

	cam = Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, aspect, 0.1, 10.0)
	imageF = @time @pipe Render(Scene(cam), width, round(Int, width / aspect), samples, depth) |>
		add_random_scene! |>
		Dtrace |>
		map(rgbf8, _) |>
		Images.save(filename, _)
end

main(filename="Drender.jpg")

