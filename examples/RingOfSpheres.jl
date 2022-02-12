using ShirleyRayTracer
using Pipe


defscene() = Scene(Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, 16/9, 0.1, 10.0), Grey(0.5))

function ring(scene)
    hitables = Vector{Hitable}()


    odd = add!(scene, SolidColor(Color(0.2, 0.3, 0.1)))
	even = add!(scene, SolidColor(Color(0.9)))
	checker = add!(scene, Checker(odd, even))
    
    add!(scene, Sphere(Point3(0,-1000,0), 1000, add!(scene, Lambertian(odd))))
#==
    sc = add!(scene, SolidColor(Color(0.4, 0.2, 0.1)))
    m1 = add!(scene, Dielectric(1.5))
    m2 = add!(scene, Lambertian(sc))
    m3 = add!(scene, Metal(Color(0.7, 0.6, 0.5), 0.0))
    push!(hitables, Sphere(Point3(0, 1, 0), 1.0, m1))
    push!(hitables, Sphere(Point3(-4, 1, 0), 1.0, m2))
    push!(hitables, Sphere(Point3(4, 1, 0), 1.0, m3))

    r = 4
    for a in 0:36:360
        x = r*sin(deg2rad(a))
        y = r*cos(deg2rad(a))
        push!(hitables, Sphere(Point3(x, y, 0), rand(), rand([m1, m2, m3])))
    end
==#
    #add!(scene, BVH(hitables, 0.0, 1.0))
    scene
end

function main(;width=1200, aspect=16/9, samples=10, depth=50, scenes=[ring])
    for sc in [ring]
        println("sc $(sc)")
        @time @pipe defscene() |> 
              sc |> 
              render(_, width, round(Int, width / aspect), samples, depth) |>
              ShirleyRayTracer.save("$(sc).jpg", _)
    end
end


