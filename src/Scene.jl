struct Scene
	camera::Camera
	hitables::Vector{Hitable}
    background::Color
	Scene(cam, bg) = new(cam, Vector{Hitable}(), bg)
end

function trace!(rec::Hit, hitables::Vector{Hitable}, ray::Ray, t_min::Float64, t_max::Float64)
	hit::Bool = false
	for hitable in hitables
		if trace!(rec, hitable, ray, t_min, t_max)
			hit = true
		end
	end
	hit
end

