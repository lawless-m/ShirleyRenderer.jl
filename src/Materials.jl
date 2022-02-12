
export Lambertian, Metal, Dielectric, DiffuseLight, Isotropic

@inline reflect(v, n) =  v - 2dot(v,n)*n
@inline function refract(uv, n, etai_over_etat) 
    cos_theta = min(dot(-uv, n), 1.0)
    r_out_perp = etai_over_etat * (uv + cos_theta*n)
    r_out_parallel = -sqrt(abs(1.0 - magnitude²(r_out_perp))) * n
    r_out_perp + r_out_parallel
end
@inline function reflectance(cosine, ratio)
	r = ((1-ratio) / (1+ratio))^2
	r + (1-r)*(1 - cosine)^5
end
#==
struct Material
	type::MaterialType
	albedo::Color
	texture::Int64
	fuzz::Float64
	ir::Float64
end
==#

Lambertian(tex::Int64) = Material(_Lambertian, zero(Color), tex, 0, 0)
@inline function scatter_lamb!(scene, ray, rec, material)::Tuple{Bool, Color}
	direction = rec.normal + random_unit_vector()
	if near_zero(direction)
		direction = rec.normal
	end
	set_ray!(ray, rec.p, direction, rec.t)
	return true, value(scene, material.texture, rec.u, rec.v, rec.p)
end

Metal(c::Color, fuzz::Float64) = Material(_Metal, c, 0, fuzz, 0)

@inline function scatter_metal!(scene, ray, rec, material)::Tuple{Bool, Color}
	reflected = reflect(unit(ray.direction), rec.normal)
	direction = reflected + material.fuzz * random_in_unit_sphere()
	if dot(direction, rec.normal) > 0 
		set_ray!(ray, rec.p, direction, rec.t)
		return true, material.albedo
	else
		return false, zero(Color)
	end
end

Dielectric(ir::Float64) = Material(_Dielectric, zero(Color), 0, 0, ir)
@inline function scatter_dielectric!(scene, ray, rec, material)::Tuple{Bool, Color}
	refraction_ratio = rec.front_face ? (1.0/material.ir) : material.ir
	udirection = unit(ray.direction)
	cos_theta = min(dot(-udirection, rec.normal), 1.0)
	sin_theta = sqrt(1.0 - cos_theta^2)
	cannot_refract::Bool = refraction_ratio * sin_theta > 1.0
	direction = if cannot_refract || reflectance(cos_theta, refraction_ratio) > rand()
			reflect(udirection, rec.normal)
		else
			refract(udirection, rec.normal, refraction_ratio)
		end
	set_ray!(ray, rec.p, direction, rec.t)
	return true, Color(1,1,1)
end

DiffuseLight(tex::Int64) = Material(_DiffuseLight, zero(Color), tex, 0, 0)
@inline scatter_diffuse!(scene, ray, rec, material)::Tuple{Bool, Color} = false, zero(Color)

Isotropic(tex::Int64) = Material(_Isotropic, zero(Color), tex, 0, 0)
@inline function scatter_isotropic!(scene, ray, rec, material)::Tuple{Bool, Color}
	set_ray!(ray, rec.p, random_in_unit_sphere(), rec.t)
	return true, value(scene, material.texture, rec.u, rec.v, rec.p)
end

const scatter_vt! = Dict{MaterialType, Function}(
	_Lambertian => scatter_lamb!, 
	_Metal => scatter_metal!,
	_Dielectric => scatter_dielectric!,
	_Isotropic => scatter_isotropic!,
	_DiffuseLight => scatter_diffuse!
	)

function scatter!(scene, ray, rec)::Tuple{Bool, Color}
	
	material = scene.materials[rec.material]

	if material.type == _Lambertian
		return scatter_lamb!(scene, ray, rec, material)
	end

	if material.type == _Metal
		return scatter_metal!(scene, ray, rec, material)
	end

	if material.type == _Dielectric
		return scatter_dielectric!(scene, ray, rec, material)
	end

	if material.type == _Isotropic
		return scatter_isotropic!(scene, ray, rec, material)
	end
	
	# _DiffuseLight
	false, zero(Color)
end


function emitted(scene, rec, u::Float64, v::Float64, p::Point3)::Color
	
	material = scene.materials[rec.material]

	if material.type == _DiffuseLight
		return value(scene, material.texture, u, v, p)
	end

	return zero(Color)
end

