
mutable struct Ray
        origin::Point3
        direction::Vec3
        time::Float64
        Ray(o, d, t) = new(o, d, t)
        Ray(o, d) = Ray(o, d, 0)
        Ray() = Ray(zero(Point3), zero(Vec3))
end

at(r::Ray, t) = r.origin + t * r.direction

function set_ray!(ray, origin, direction, time)
        ray.origin = origin
        ray.direction = direction
        ray.time = time
        ray
end

function reset_ray!(cam, ray, s, t)
        x, y = cam.lens_radius .* random_in_unit_disk()
        offset = cam.u * x + cam.v * y
        set_ray!(ray, cam.origin + offset, cam.lower_left_corner + s * cam.horizontal + t * cam.vertical - cam.origin - offset, randf(cam.time0, cam.time1))
end

function ray_color!(scene, ray, rec, depth)
        if depth <= 0
                return zero(Color)
        end
        hit = trace!(scene, ray, rec, 0.001, Inf)
        if !hit
                t = 0.5*(unit(ray.direction)[2] + 1.0)
                return (1.0 - t) + t * Color(0.5, 0.7, 1.0)
        end

        scattered, attenuation = scatter!(rec.material, ray, rec)
        if !scattered
                return Color(0,0,0)
        end
        attenuation * ray_color!(scene, ray, rec, depth-1)
end

