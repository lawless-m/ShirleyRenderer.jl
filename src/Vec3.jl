
const Vec3 = Tuple{Float64, Float64, Float64}
const Vec3I = Tuple{Int64, Int64, Int64}
const Point3 = Vec3

Vec3(a,b,c) = Vec3((a,b,c))
Base.zero(::Type{Vec3}) = Vec3(0,0,0)

x(v::Vec3) = v[1]
y(v::Vec3) = v[2]
z(v::Vec3) = v[3]

import Base.+, Base.*, Base.-, Base./
+(a::Vec3, b::Vec3) = a .+ b
*(a::Vec3, b::Vec3) = a .* b
*(a::Vec3, b::Float64) = a .* b
*(a::Real, b::Vec3) = b .* a
-(a::Vec3, b::Vec3) = a .- b
-(a::Vec3) = Vec3(-a[1], -a[2], -a[3])
/(a::Vec3, b::Vec3) = a ./ b
/(a::Vec3, b::Real) = a ./ b
/(a::Float64, b::Vec3) = b ./ a

magnitude(x,y) = sqrt(x^2 + y^2)
magnitude(x,y,z) = sqrt(x^2 + y^2 + z^2)
magnitude(v) = magnitude(v...)

magnitudesq(x,y) = x^2 + y^2
magnitudesq(x,y,z) = x^2 + y^2 + z^2
magnitudesq(v) = magnitudesq(v...)

dot(a::Vec3, b::Vec3) = a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
cross(a::Vec3, b::Vec3) = Vec3(a[2] * b[3] - a[3] * b[2],
                               a[3] * b[1] - a[1] * b[3],
                               a[1] * b[2] - a[2] * b[1])

unit(v::Vec3) = v ./ magnitude(v)
near_zero(v) = v[1] < 1e-8 && v[2] < 1e-8 && v[3] < 1e-8

randf(fmin, fmax) = fmin + (fmax-fmin)*rand()
randv() = Vec3(rand(), rand(), rand())
randv(l, h) = Vec3(randf(l,h), randf(l,h), randf(l,h))
randu() = unit(randv(-1, 1))
