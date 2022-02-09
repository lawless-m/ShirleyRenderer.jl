using ShirleyRayTracer

function rc_warn()
    scene = Scene(Camera(Point3(13.,2.,3.), zero(Point3), Vec3(0,1,0), 20, 16/9, 0.1, 10.0), Color(0.5,0.5,0.5))
    add!(scene, Sphere(Point3(0, 1, 0), 1.0, Dielectric(1.5)))
    add!(scene, Sphere(Point3(-4, 1, 0), 1.0, Lambertian(Color(0.4,0.2,0.1))))
    add!(scene, Sphere(Point3(4, 1, 0), 1.0, Metal(Color(0.7,0.6,0.5), 0.0)))

    rec = ShirleyRayTracer.Hit()
    ray = ShirleyRayTracer.Ray()

    @code_warntype ShirleyRayTracer.ray_color!(rec, ray, scene, 20)
   # @code_warntype ShirleyRayTracer.scatter!(scene, ray, rec)
end
