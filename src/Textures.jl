
export Checker, SolidColor, Noise, TextureMap

value(t::Texture)::Color = Color(0,0,0)
struct SolidColor <: Texture
    c::Color
end
value(sc::SolidColor, u, v, p) = sc.c

struct Checker <: Texture
    odd
    even
    Checker(o::Texture, e::Texture) = new(o, e)
    Checker(o::Color, e::Color) = Checker(SolidColor(o), SolidColor(e))
end    

value(c::Checker, u, v, p) = sin(10p.x) * sin(10p.y) * sin(10p.z) < 0 ? value(c.odd, u, v, p) : value(c.even, u, v, p)

struct Noise <: Texture
    noise
    scale
    Noise(s; point_count=256) = new(Perlin(point_count), s)
end

function value(n::Noise, u, v, p)::Color
    v = 1 + sin(n.scale*p.z + 10*turb(n.noise, p))
    Color(0.5v, 0.5v, 0.5v)
end

struct TextureMap <: Texture
    rgb
    TextureMap(fname::AbstractString) = new(load(fname))
end

function value(tm::TextureMap, u, v, p)
    h, w = size(tm.rgb)
    i = 1 + round(Int, clamp(u, 0, 1) * (w-1))
    j = 1 + round(Int, clamp(v, 0, 1) * (h-1))
    Color(tm.rgb[j,i])
end
