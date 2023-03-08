-- basic functions for handling values as bitfields

local math_floor = math.floor;

bit32 = {};

local pow2Table = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536};
local pow2 = function( n )
	return pow2Table[n+1] or 2^n;
end

bit32.lshift = function( n, shift )
	return n * pow2( shift );
end

bit32.rshift = function( n, shift )
	return math_floor( n / pow2( shift ) );
end

bit32.extract = function( n, field, width )
	width = width or 1;
	
	if field > 0 then
		n = bit32.rshift( n, field );
	end
	
	return n % pow2( width );
end