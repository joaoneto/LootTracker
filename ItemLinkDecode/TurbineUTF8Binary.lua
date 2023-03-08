-- Turbine makes use of the \u01xx unicode page to encode binary data as 'readable' lua strings (UTF8). 
-- Through that encoding scheme, each binary byte ends up encoded as a two-bytes UTF8 character. (Cx xx)

-- The TurbineUTF8Binary functions provides encoding and decoding for that scheme

TurbineUTF8Binary = {};

-- build lookup tables for encoding/decoding
-- note: table indices start at 1, values will have to be shifted accordingly

local EncodeArray = { "Ā","ā","Ă","ă","Ą","ą","Ć","ć","Ĉ","ĉ","Ċ","ċ","Č","č","Ď","ď","Đ","đ","Ē","ē","Ĕ","ĕ","Ė","ė","Ę","ę","Ě","ě","Ĝ","ĝ","Ğ","ğ","Ġ","ġ","Ģ","ģ","Ĥ","ĥ","Ħ","ħ","Ĩ","ĩ","Ī","ī","Ĭ","ĭ","Į","į","İ","ı","Ĳ","ĳ","Ĵ","ĵ","Ķ","ķ","ĸ","Ĺ","ĺ","Ļ","ļ","Ľ","ľ","Ŀ","ŀ","Ł","ł","Ń","ń","Ņ","ņ","Ň","ň","ŉ","Ŋ","ŋ","Ō","ō","Ŏ","ŏ","Ő","ő","Œ","œ","Ŕ","ŕ","Ŗ","ŗ","Ř","ř","Ś","ś","Ŝ","ŝ","Ş","ş","Š","š","Ţ","ţ","Ť","ť","Ŧ","ŧ","Ũ","ũ","Ū","ū","Ŭ","ŭ","Ů","ů","Ű","ű","Ų","ų","Ŵ","ŵ","Ŷ","ŷ","Ÿ","Ź","ź","Ż","ż","Ž","ž","ſ","ƀ","Ɓ","Ƃ","ƃ","Ƅ","ƅ","Ɔ","Ƈ","ƈ","Ɖ","Ɗ","Ƌ","ƌ","ƍ","Ǝ","Ə","Ɛ","Ƒ","ƒ","Ɠ","Ɣ","ƕ","Ɩ","Ɨ","Ƙ","ƙ","ƚ","ƛ","Ɯ","Ɲ","ƞ","Ɵ","Ơ","ơ","Ƣ","ƣ","Ƥ","ƥ","Ʀ","Ƨ","ƨ","Ʃ","ƪ","ƫ","Ƭ","ƭ","Ʈ","Ư","ư","Ʊ","Ʋ","Ƴ","ƴ","Ƶ","ƶ","Ʒ","Ƹ","ƹ","ƺ","ƻ","Ƽ","ƽ","ƾ","ƿ","ǀ","ǁ","ǂ","ǃ","Ǆ","ǅ","ǆ","Ǉ","ǈ","ǉ","Ǌ","ǋ","ǌ","Ǎ","ǎ","Ǐ","ǐ","Ǒ","ǒ","Ǔ","ǔ","Ǖ","ǖ","Ǘ","ǘ","Ǚ","ǚ","Ǜ","ǜ","ǝ","Ǟ","ǟ","Ǡ","ǡ","Ǣ","ǣ","Ǥ","ǥ","Ǧ","ǧ","Ǩ","ǩ","Ǫ","ǫ","Ǭ","ǭ","Ǯ","ǯ","ǰ","Ǳ","ǲ","ǳ","Ǵ","ǵ","Ƕ","Ƿ","Ǹ","ǹ","Ǻ","ǻ","Ǽ","ǽ","Ǿ","ǿ" };

-- we just build a reverse lookup table for decoding
local DecodeTable = {};
for k,v in ipairs( EncodeArray ) do
	DecodeTable[v] = k;
end

-- constructor
function TurbineUTF8Binary:Constructor()
	Turbine.Object.Constructor( self );
end

-- Decode takes a lua string (UTF8) as an argument and returns binary data as an array of bytes (int values 0..255)
function TurbineUTF8Binary.Decode( encodedString )
	local decodedArray = {};
	for c in string.gmatch( encodedString, ".." ) do
		table.insert( decodedArray, DecodeTable[c] - 1 );
	end
	return decodedArray;
end

-- converts a byte array or binary string into a human legible hexadecimal string 
function TurbineUTF8Binary.HexString( input )
	local HexTable = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" };
	local hexCodes = {};
	if type( input ) == "table" then
		for _, byte in ipairs( input ) do
			local lowNibble = math.mod( byte, 16 );
			local highNibble = math.floor( byte / 16 );
			table.insert( hexCodes, HexTable[ highNibble + 1 ] );
			table.insert( hexCodes, HexTable[ lowNibble + 1 ] );
		end
		return table.concat( hexCodes );
	end
	
	if type( input ) == "string" then
		for c in string.gmatch( input, "." ) do 
			local byte = string.byte( c );
			local lowNibble = math.mod( byte, 16 );
			local highNibble = math.floor( byte / 16 );
			table.insert( hexCodes, HexTable[ highNibble + 1 ] );
			table.insert( hexCodes, HexTable[ lowNibble + 1 ] );
		end
		return table.concat( hexCodes );
	end
end

-- Encode takes an array of bytes (int values 0..255) as an argument and returns an encoded lua string (UTF8)
function TurbineUTF8Binary.Encode( inputBytes )
	--[[	lua does not handle UTF8, and has no low level string/buffer manipulation methods,  
	so we first build an intermediate array, one entry for each characters of the encoded UTF8 
	sequence which we then turn into a lua string using table.concat.
	--]]

	local encodedBytes = {};
	for _, byte in ipairs( inputBytes ) do
		local utf8char = EncodeArray[ byte + 1 ];
		-- get the numeric values of the two bytes of the UTF8 character
		table.insert( encodedBytes, utf8char );
	end
	return table.concat( encodedBytes ); 
end