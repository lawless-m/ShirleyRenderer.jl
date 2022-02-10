using ShirleyRayTracer
using Pipe


rand_grey(low=0, high=1) = Color(randf(low, high))



function random_scene(scene; filename="")
    
    checker = Checker(Color(0.2, 0.3, 0.1), Color(0.9))

    hitables = Vector{Hitable}()
    push!(hitables, Sphere(Point3(0,-1000,0), 1000, Lambertian(checker)))

    for a in -11:10, b in -11:10
        choose_mat = rand()
        center = Point3(a + 0.9rand(), 0.2, b + 0.9rand())
        if magnitude(center - Vec3(4, 0.2, 0)) > 0.9
            if choose_mat < 0.8
                # // diffuse
                center2 = center + Vec3(0, randf(0,.5), 0)
                push!(hitables, MovingSphere(center, center2, 0.0, 1.0, 0.2, Lambertian()))
            elseif choose_mat < 0.95
                #  // metal
                push!(hitables, Sphere(center, 0.2, Metal(Grey(randf(0.5, 1)), randf(0, 0.5))))
            else
                #    // glass
                push!(hitables, Sphere(center, 0.2, Dielectric(1.5)))
            end 
        end
    end

    push!(hitables, Sphere(Point3(0, 1, 0), 1.0, Dielectric(1.5)))
    push!(hitables, Sphere(Point3(-4, 1, 0), 1.0, Lambertian(Color(0.4, 0.2, 0.1))))
    push!(hitables, Sphere(Point3(4, 1, 0), 1.0, Metal(Color(0.7, 0.6, 0.5), 0.0)))
    add!(scene, BVH(hitables, 0.0, 1.0))
    scene
end

function two_spheres(scene; filename="")
    checker = Lambertian(Checker(Color(0.2, 0.3, 0.1), Color(0.9, 0.9, 0.9)))
    add!(scene, Sphere(Point3(0,-10, 0), 10, checker))
    add!(scene, Sphere(Point3(0,10, 0), 10, checker))
    scene
end

function two_perlin_spheres(scene; filename="")
    perlin = Lambertian(Noise(4))
    add!(scene, Sphere(Point3(0,-1000,0), 1000, perlin))
    add!(scene, Sphere(Point3(0,2,0), 2, perlin))
    scene
end

function earth(scene; filename="earthmap.jpg")    
    t = Lambertian(TextureMap(filename))
    add!(scene, Sphere(Point3(0, 1, 0), 1.0, t))
    add!(scene, Sphere(Point3(-4, 1, 0), 1.0, t))
    add!(scene, Sphere(Point3(4, 1, 0), 1.0, t))
    scene
end

function simple_light(scene; filename="")
    perlin = Lambertian(Noise(4))
    add!(scene, Sphere(Point3(0,-1000,0), 1000, perlin))
    add!(scene, Sphere(Point3(0,2,0), 2, perlin))

    difflight = DiffuseLight(Color(4,4,4))
    add!(scene, Sphere(Point3(0,7,0), 2, difflight))
    add!(scene, XYRect(3, 5, 1, 3, -2, difflight))
    scene
end

function cornell_box(scene; filename="")
    red = Lambertian(Color(.65, .05, .05))
    white = Lambertian(Color(.73, .73, .73))
    green = Lambertian(Color(.12, .45, .15))
    light = Lambertian(Color(15, 15, 15))

    add!(scene, YZRect(0, 555, 0, 555, 555, green))
    add!(scene, YZRect(0, 555, 0, 555, 0, red))
    add!(scene, XZRect(213, 343, 227, 332, 554, light))
    add!(scene, XZRect(0, 555, 0, 555, 0, white))
    add!(scene, XZRect(0, 555, 0, 555, 555, white))
    add!(scene, XYRect(0, 555, 0, 555, 555, white))

    box = @pipe Box(Point3(0,0,0), Point3(165,330,165), white) |> 
        RotateY(_, 15) |>
        Translate(_, Vec3(265,0,295))
    add!(scene, box)

    box = @pipe Box(Point3(0,0,0), Point3(165,165,165), white) |>
        RotateY(_, -18) |>
        Translate(_, Vec3(130,0,65))
    add!(scene, box)
    scene
end

function cornell_smoke(scene; filename="")
    red = Lambertian(Color(.65, .05, .05))
    white = Lambertian(Color(.73, .73, .73))
    green = Lambertian(Color(.12, .45, .15))
    light = Lambertian(Color(7,7,7))

    add!(scene, YZRect(0, 555, 0, 555, 555, green))
    add!(scene, YZRect(0, 555, 0, 555, 0, red))
    add!(scene, XZRect(113, 443, 127, 432, 554, light))
    add!(scene, XZRect(0, 555, 0, 555, 555, white))
    add!(scene, XZRect(0, 555, 0, 555, 0, white))
    add!(scene, XYRect(0, 555, 0, 555, 555, white))

    box = @pipe Box(Point3(0,0,0), Point3(165,330,165), white) |> 
        RotateY(_, 15) |>
        Translate(_, Vec3(265,0,295))

    add!(scene, ConstantMedium(box, 0.01, Isotropic(Color(0,0,0))))

    box = @pipe Box(Point3(0,0,0), Point3(165,165,165), white) |>
        RotateY(_, -18) |>
        Translate(_, Vec3(130,0,65))

    add!(scene, ConstantMedium(box, 0.01, Isotropic(Color(1,1,1))))
    scene
end

function final_scene(scene; filename="earthmap.jpg")
    
    ground = Lambertian(Color(0.48, 0.83, 0.53))

    boxes = Vector{Hitable}()
    boxes_per_side = 20;
    for i in 0:boxes_per_side-1, j in 0:boxes_per_side-1
        x0 = -1000 + 100i
        z0 = -1000 + 100j
        x1 = x0 + 100
        y1 = randf(1, 101)
        z1 = z0 + 100
        push!(boxes, Box(Point3(x0, 0, z0), Point3(x1, y1, z1), ground))
    end

    add!(scene, BVH(boxes, 0, 1))

    light = DiffuseLight(Color(7, 7, 7))

    add!(scene, XZRect(123, 423, 147, 412, 554, light))

    center1 = Point3(400, 400, 200)
    center2 = center1 + Vec3(30,0,0)

    add!(scene, MovingSphere(center1, center2, 0, 1, 50, Lambertian(Color(0.7, 0.3, 0.1))))
    add!(scene, Sphere(Point3(260, 150, 45), 50, Dielectric(1.5)))
    add!(scene, Sphere(Point3(0, 150, 145), 50, Metal(Color(0.8, 0.8, 0.9), 1.0)))
    
    boundary = Sphere(Point3(360,150,145), 70, Dielectric(1.5))
    add!(scene, boundary)
    add!(scene, ConstantMedium(boundary, 0.2, Isotropic(Color(0.2, 0.4, 0.9))))
    
    boundary = Sphere(Point3(0,0,0), 5000, Dielectric(1.5))
    add!(scene, ConstantMedium(boundary, .0001, Isotropic(Grey(1))))

    add!(scene, Sphere(Point3(400,200,400), 100, Lambertian(TextureMap(filename))))
    add!(scene, Sphere(Point3(220,280,300), 80, Lambertian(Noise(0.1))))
    boxes = Vector{Hitable}()
    white = Lambertian(Grey(.73))
    for _ in 1:1000
        r = randf(0, 165)
        push!(boxes, Sphere(Point3(r,r,r), 10, white))
    end

    add!(scene, @pipe BVH(boxes, 0.0, 1.0) |> RotateY(_, 15) |> Translate(_, Vec3(-100,270,395)))
    scene
end

defscene() = Scene(Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, 16/9, 0.1, 10.0), Grey(0.5))

function main(;width=1200, aspect=16/9, samples=10, depth=50, mapfilename="/home/matt/GitHub/ShirleyRenderer.jl/examples/earthmap.jpg", scenes=[random_scene, two_spheres, two_perlin_spheres, earth, simple_light, cornell_box, cornell_smoke, final_scene])
	image_height = 
    for sc! in scenes
        println("sc $(sc!)")
        @time @pipe defscene() |> 
              sc!(_; filename=mapfilename) |> 
              render(_, width, round(Int, width / aspect), samples, depth) |>
              ShirleyRayTracer.save("$(sc!).jpg", _)
    end
end
