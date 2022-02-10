struct Scene
	camera::Camera
	background::Color
	hitables::Vector{Hitable}
	materials::Vector{Material}
	textures::Vector{Texture}
	Scene(cam, bg) = new(cam, bg, Vector{Hitable}(), Vector{Material}(), Vector{Texture}())
end

add!(s::Scene, h::Hitable)  = begin push!(s.hitables, h); length(s.hitables); end
add!(s::Scene, m::Material) = begin push!(s.materials, m); length(s.materials); end
add!(s::Scene, t::Texture)  = begin push!(s.textures, t); length(s.textures); end

function trace!(hitables::Vector{Hitable}, ray::Ray, rec::Hit, t_min::Float64, t_max::Float64)
	hit::Bool = false
	for hitable in hitables
		if trace!(hitable, ray, rec, t_min, t_max)
			hit = true
		end
	end
	hit
end
