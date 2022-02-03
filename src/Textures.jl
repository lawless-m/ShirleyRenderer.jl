
export Checker, SolidColor

value(t::Texture) = 0,0,0

struct SolidColor <: Texture
    color::Color
end

value(s::SolidColor, u, v, p) = s.color

struct Checker <: Texture
    odd::Texture
    even::Texture
    Checker(o, e) = new(o,e)
    Checker(o::Color, e::Color) = Checker(SolidColor(o), SolidColor(e))
end

value(c::Checker, u, v, p) = sin(10p.x) * sin(10p.y) * sin(10p.z) < 0 ? value(odd, u, v, p) : value(even, u, v, p)

