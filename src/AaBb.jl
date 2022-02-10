
struct AaBb
    min::Point3
    max::Point3
end

function trace!(aabb::AaBb, ray, rec, t_min, t_max)
    for a in 1:3
        a1 = (aabb.min[a] - ray.origin[a]) / ray.direction[a]
        a2 = (aabb.max[a] - ray.origin[a]) / ray.direction[a]
        if min(max(a1, a2), t_max) <= max(min(a1, a2), t_min)
            return false
        end
    end
    true
end

minmax_xyz(aabb) = aabb.max[1] - aabb.min[1], aabb.max[2] - aabb.min[2], aabb.max[3] - aabb.min[3]
    
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
        x = p[1] < x ? p[1] : x
        y = p[2] < y ? p[2] : y
        z = p[3] < z ? p[3] : z
        # max
        X = p[1] > X ? p[1] : X
        Y = p[2] > y ? p[2] : Y
        Z = p[3] > Z ? p[3] : Z
    end
catch e
	for b in boxes
	    println(stderr, b)
	end
    println(e)
	exit()
end
    AaBb(Point3(x,y,z), Point3(X,Y,Z))
end
