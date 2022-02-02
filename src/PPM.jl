
export write_ppm

clamp(f, b, t) = f < b ? b : f > t ? t : f

function write_ppm(io, scanlines)
    h = length(scanlines)
    if h == 0
        return false
    end
    w = length(scanlines[1])

    function write(io::IO, c)
        val(rgb) = round(Int, 255clamp(sqrt(rgb), 0, 1))
        println(io, "$(val(c[1])) $(val(c[2])) $(val(c[3]))")
    end

	println(io, "P3\n$w $h\n255")
	foreach(scanline->foreach(p->write(io, p), scanline), scanlines[end:-1:1])
end
