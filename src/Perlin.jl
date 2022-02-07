

struct Perlin
    point_count
    ranvec
    perm_x
    perm_y
    perm_z
    Perlin(point_count=256) = new(point_count, [normalize(Vec3(randf(-1,1), randf(-1,1), randf(-1,1))) for _ in 1:point_count], shuffle(1:point_count), shuffle(1:point_count), shuffle(1:point_count))
end

function noise(p::Perlin, at::Point3)
    i = floor(Int, at.x)
    j = floor(Int, at.y)
    k = floor(Int, at.z)
    u = at.x - i
    v = at.y - j
    w = at.z - k
    c = Array{Float64}(undef, 2,2,2)

    for di in 1:2, dj in 1:2, dj in 1:2
        c[di, dj, dk] = ranvec[
            p.perm_x[(i+di)&255] ^
            p.perm_y[(i+dj)&255] ^
            p.perm_z[(i+dk)&255]
        ]
    end

    perlin_interp(c, u, v, w)
end

function perlin_interp(c, u, v, w)
    uu = u^2 * (3-2u)
    vv = v^2 * (3-2v)
    ww = w^2 * (3-2w)
    a = 0.0
    for i in 1:2, j in 1:2, k in 1:2
        a += (i*uu + (1-i)*(1-uu)) *
             (j*vv + (1-j)*(1-vv)) *
             (k*ww + (1-k)*(1-ww)) *
             dot(c[i,j,k], Vec3(u-i, v-j, w-k))
    end
    a
end

function turb(p::Perlin, at, depth)
    a = 0
    weight = 1.0
    for i in 1:depth
        a += weight * noise(p, at)
        weight = 0.5
        at *= 2 
    end
    abs(a)
end

