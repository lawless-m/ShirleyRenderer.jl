
const Vec3 = Tuple{Float64, Float64, Float64}
const Vec3I = Tuple{Int64, Int64, Int64}
const Point3 = Vec3
const Color = Vec3

export Vec3, Point3, Color, Grey, magnitude, magnitude², dot, cross, unit, randf, randv, near_zero

Vec3(a,b,c) = Vec3((a,b,c))
Vec3(f::Float64) = Vec3(f,f,f)
Base.zero(::Type{Vec3}) = Vec3(0,0,0)
Color() = Vec3(rand() * rand(), rand() * rand(), rand() * rand())
Color(rgb::RGB{N0f8}) = Vec3(rgb.r, rgb.g, rgb.b)
Grey(c::Float64) = Color(c,c,c)
Grey(c::Int) = Color(Float64(c))

x(v::Vec3) = v[1]
y(v::Vec3) = v[2]
z(v::Vec3) = v[3]

import Base.+, Base.*, Base.-, Base./

+(a::Vec3, b::Vec3) = a .+ b
+(a::Vec3, b::Float64) = a .+ b
+(a::Vec3, b::Int64) = a .+ b

+(a::Float64, b::Vec3) = a .+ b
+(a::Int64, b::Vec3) = a .+ b

*(a::Vec3, b::Vec3) = a .* b
*(a::Vec3, b::Float64) = a .* b
*(a::Vec3, b::Int64) = a .* b
*(a::Float64, b::Vec3) = b .* a

-(a::Vec3, b::Vec3) = a .- b
-(a::Vec3) = Vec3(-a[1], -a[2], -a[3])

/(a::Vec3, b::Vec3) = a ./ b
/(a::Vec3, b::Float64) = a ./ b
/(a::Vec3, b::Int64) = a ./ b

magnitude(x,y) = sqrt(magnitude²(x,y))
magnitude(x,y,z) = sqrt(magnitude²(x,y,z))
magnitude(v) = sqrt(magnitude²(v))

magnitude²(x,y) = x^2 + y^2
magnitude²(x,y,z) = x^2 + y^2 + z^2
magnitude²(v) = magnitude²(v...)

dot(a::Vec3, b::Vec3) = a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
cross(a::Vec3, b::Vec3) = Vec3(a[2] * b[3] - a[3] * b[2],
                               a[3] * b[1] - a[1] * b[3],
                               a[1] * b[2] - a[2] * b[1])

unit(v::Vec3) = v ./ magnitude(v)
near_zero(v) = v[1] < 1e-8 && v[2] < 1e-8 && v[3] < 1e-8

randf(fmin, fmax) = fmin + (fmax-fmin)*rand()
randv() = Vec3(rand(), rand(), rand())
randv(l, h) = Vec3(randf(l,h), randf(l,h), randf(l,h))

function random_in_unit_disk()
	x,y = randf(-1, 1), randf(-1, 1)
	while magnitude²(x,y) >= 1
     	x,y = randf(-1, 1), randf(-1, 1)
	end
	x,y
end

function random_in_unit_sphere() 
	v = randv(-1,1)
	while magnitude²(v) >= 1
		v = randv(-1,1)
	end
	v
end

random_unit_vector() = unit(random_in_unit_sphere())

function random_in_hemisphere(normal) 
    in_unit_sphere = random_in_unit_sphere()
    dot(in_unit_sphere, normal) > 0.0 ? in_unit_sphere : -in_unit_sphere
end
