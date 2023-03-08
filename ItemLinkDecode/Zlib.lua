-- Basic implementation of the zlib library in lua
-- FDICT is not supported
-- the static huffman codes method is not supported

Zlib = {};

-- inflate (uncompress) data
-- Data is a binary string
-- returns an array of bytes
function Zlib.Inflate( data )
	inflatedData = {};
	local outputFun = function ( byte )
		table.insert( inflatedData, byte );
	end
	
	-- Equendil.LIP.ItemDecode.ZlibDeflate.inflate_zlib( { input = data, output = outputFun, disable_crc=false });
	-- LootTracker.ItemLinkDecode.Inflate
	ZlibDeflate.inflate_zlib({ input = data, output = outputFun, disable_crc = false });
	
	return inflatedData;
end
