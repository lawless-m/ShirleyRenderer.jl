
struct AaBb
    min::Point3
    max::Point3
end

function trace!(rec, aabb::AaBb, ray, t_min, t_max)
    for a in 1:3
        a1 = (aabb.min[a] - ray.origin[a]) / ray.direction[a]
        a2 = (aabb.max[a] - ray.origin[a]) / ray.direction[a]
        if min(max(a1, a2), t_max) <= max(min(a1, a2), t_min)
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

function surrounding_box(boxes::Vector{AaBb})
    x=y=z = Inf
    X=Y=Z = -Inf
try
    for box in boxes, p in (box.min, box.max)
        # min
        x = p.x < x ? p.x : x
        y = p.y < y ? p.y : y
        z = p.z < z ? p.z : z
        # max
        X = p.x > X ? p.x : X
        Y = p.y > y ? p.y : Y
        Z = p.z > Z ? p.z : Z
    end
catch
	for b in boxes
	println(stderr, b)
	end
	exit()
end
    AaBb(Point3(x,y,z), Point3(X,Y,Z))
end
