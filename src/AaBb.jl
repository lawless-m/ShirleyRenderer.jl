
struct AaBb
    min::Point3
    max::Point3
end

function hit(aabb::AaBb, ray, t_min, t_max)
    for a in 1:3
        a1 = aabb.min[a] - ray.origin[a]) / ray.direction[a]
        a2 = aabb.max[a] - ray.origin[a]) / ray.direction[a]
        if (min(max(a1, a2), t_max) <= max(min(a1, a2), t_min))
            return false
        end
    end
    true
end

minmax_xyz(aabb) = aabb.max.x - aabb.min.x, aabb.max.y - aabb.min.y, aabb.max.z - aabb.min.z
    
function area(aabb::AaBb)
    x,y,z = minmax_xyz(aabb)
    2(x*y + y*z + z*x)
end

function longest_axis(aabb::AaBb)
    x,y,z = minmax_xyz(aabb)
    (x > y && x > z) ? 1 : y > z ? 2 : 3
end

surrounding_box(box0, box1) = aabb(
        Point3(min(box0.min.x, box1.min.x), min(box0.min.y, box1.min.y), min(box0.min.z, box1.min.z)),
        Point3(max(box0.min.x, box1.min.x), max(box0.min.y, box1.min.y), max(box0.min.z, box1.min.z))
        )

