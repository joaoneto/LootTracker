
--[[

DecodeLink( data, isLI ) : Decodes an item link

- 'data' must be an encoded string from an item link, 
either from <ExamineIA:IAInfo:*> or <ExamineItemInstance:ItemInfo:*>

for instance: 
local data, name = string.match( chatLine, "<ExamineIA:IAInfo:(.-)>(%b[])<\\ExamineIA>" )
or
local data, name = string.match( chatLine, "<ExamineItemInstance:ItemInfo:(.-)>(%b[])<\\ExamineItemInstance>" )

- 'isLi' must be true if the data refers to a LI, false otherwise

- returns a table with the following possible fields:

itemIIDLow		- instance item ID, least significant 32 bits
itemIIDHigh		- instance item ID, most significant 32 bits
itemGID		- generic item ID
itemCraftedBy	- name of the crafter
itemBoundToLow	- ID of player / account / placeholder ID to which the item is bound, least significant 32 bits
itemBoundToHigh	- ID of player / account / placeholder ID to which the item is bound, most significant 32 bits
itemTrueLevel	- true level of the item, can be > level to equip
itemName		- name of the (crafted) item
itemLevel		- level of the item (to equip)
itemUpgrades	- number of upgrades (crystals)
itemWorth		- worth of the item (in copper coins)
itemQuantity	- number of items in stack (if relevant)
itemStorageInfo	- where the item is stored (32bits, needs further decoding)
itemDye		- color of the item
itemBindToAccount - whether the item binds to account
itemBindOnAcquire - whether the item binds on acquire
itemArmour		- armour value of the item

liName		- name of LI as named by the player (as opposed to crafted name)
liTitleID		- ID to a LI title if applied
liLegacies		- a table of legacies { { ID-1, rank-1 }, { ID-2, rank-2 } ... {ID-n, rank-n) }
liRelics		- a table of relics { { ID-1, slot-1 }, { ID-2, slot-2 } .. {ID-n, slot-n} }, where 'slot' is a number between 1-4 refering to setting/gem/rune/crafted.
liStats		- a table of stats { ID-1, ID-2, ... ID-n }
liPointsSpent	- legendary points that have been spent
liPointsLeft		- legendary points that are left to spend
liDPSRank		- rank of the DPS legacy if a melee/ranged weapon
liDefaultLegacyID	- ID of the 'default' legacy if not a melee/ranged weapon (Tactical Damage Rating, Tactical Healing Rating, Shield Use, etc)
liDefaultLegacyRank	- rank of the afore mentioned 'default' legacy if not a melee/ranged weapon
liLevel		- Level of the LI (1-70)
liMaxHit		- max hit of melee damage range, in single precision floating point format (IEEE 754-2008)
			- for 'tactical' weapons (LM staff, minstrel weapon, RK stone). 
			- Min hit and dps can be computed thus: 
				- Min hit = 3/5 of max hit. 
				- DPS = (4/5 of max hit) / (attack duration of weapon) 
				- attack duration is 2.5s for 2h, 1.9s for 1h
--]]

local DecodeName = function( byteStream )
	local nameLen = byteStream:Get();
	local nameArray = {};
	for i = 1, nameLen do
		table.insert( nameArray, byteStream:GetWordLE() );
	end
	local name = string.char( unpack( nameArray ) );
	return name;
end

	
function DecodeLinkData( data, isLI )
	-- Unencode and uncompress the data
	local decodedTable = TurbineUTF8Binary.Decode( data );
	local deflatedDataAsString = string.char( unpack( decodedTable ) );
	deflatedDataAsString = string.sub( deflatedDataAsString, - ( string.len( deflatedDataAsString ) - 8 ) );
	local inflatedData = Zlib.Inflate( deflatedDataAsString );

	-- set up the data as a 'stream', sort of
	local ins = ByteStream();
	ins:SetData( inflatedData );
	
-- Retrieve what info we can
	result = {};
	
	-- Instance ID
	result.itemIIDLow = ins:GetLongLE();
	result.itemIIDHigh = ins:GetLongLE();

	-- Generic ID
	result.itemGID = ins:GetLongLE();
	
	if isLI then
		-- item name
		local fName = ins:Get();
		if fName == 1 then
			result.liName = DecodeName( ins );
		else
			result.liNameID1 = ins:GetLongLE();
			result.liNameID2 = ins:GetLongLE();
		end

		-- ??
		ins:Consume(6); 
		
		-- LI title
		result.liTitleID = ins:GetLongLE(4); 
		
		-- legacies
		ins:Consume(1); -- ??

		local nLegs = ins:Get();
		if nLegs ~= 0 then
			local legacies = {};
			for i = 1, nLegs do
				local ID = ins:GetLongLE();
				local rank = ins:GetLongLE();
				table.insert( legacies, { ["ID"] = ID, ["rank"] = rank } );
			end
			result.liLegacies = legacies;
		end
		
		-- relics
		local fRelics = ins:Get();
		local nRelics = ins:Get();
		if nRelics ~= 0 then
			local relics = {};
			for i = 1, nRelics do
				local ID = ins:GetLongLE();
				local slot = ins:GetLongLE();
				table.insert( relics, { ["ID"] = ID, ["slot"] = slot } );
			end
			result.liRelics = relics;
		end
		
		-- item stat IDs, if we have 3 or more, assume it's a two handed weapons
		local nStats = ins:GetLongLE();
		if nStats ~= 0 then
			local stats = {};
			for i = 1, nStats do
				local ID = ins:GetLongLE();
				table.insert( stats, ID );
			end
			result.liStats = stats;
		end
		
		-- points spent / left
		result.liPointsSpent = ins:GetLongLE();
		result.liPointsLeft = ins:GetLongLE();
		
		-- default legacy
		result.liDPSRank = ins:GetLongLE();
		result.liDefaultLegacyID = ins:GetLongLE();
		result.liDefaultLegacyRank = ins:GetLongLE();

		-- extra info as an array 
		local header = ins:GetLongLE();
		if header ~= 0x100010EF then
			Log.Error( "Item Decoding", "missing 100010EF header" );
			return nil;
		end
	end
		
	ins:Consume(1);
	local nSubs = ins:Get();
	for i = 1, nSubs do 
		header = ins:GetLongLE();
		header2 = ins:GetLongLE();
		if header == nil then
			Log.Error( "Item Decoding", string.format( "Top level header is nil" ) );
		elseif header ~= header2 then
			Log.Error( "Item Decoding", string.format( "Top level headers not matching: %08x - %08x" ) );
			return nil;
		elseif header == 0x100012C5 then 
			-- extra extra info as another array therein...
			local nExtras = ins:GetLongLE();
			for i = 1, nExtras do 
				local header = ins:GetLongLE();
				if header == 0x10000E20 then	
					-- crafted by ... 
					ins:Consume(1);
					result.itemCraftedBy = DecodeName( ins );
					ins:Consume( 6 );
				elseif header == 0x10000AC1 then
					-- bound to 
					result.itemBoundToLow = ins:GetLongLE();
					result.itemBoundToHigh = ins:GetLongLE();
				elseif header == 0x10001D5F then
					-- LI level
					result.liLevel = ins:GetLongLE();
				elseif header == 0x100031A4 then
					-- default legacy rank
					ins:Consume( 4 );
				elseif header == 0x100026BC then
					-- legacies, we have them already
					local nLegs = ins:GetLongLE();
					ins:Consume( 8 * nLegs );
				elseif header == 0x10000669 then
					-- virtual level
					result.itemTrueLevel = ins:GetLongLE();
				elseif header == 0x10000884 then
					-- crafting name
					ins:Consume(1);
					result.itemName = DecodeName( ins );
					ins:Consume( 6);
				elseif header == 0x100000C4 then
					-- item level
					result.itemLevel = ins:GetLongLE();
				elseif header == 0x10004996 then
					-- upgrades (crystals)
					result.itemUpgrades = ins:GetLongLE();
				elseif header == 0x100038A7 then -- Binds  to account ?
					result.itemBindToAccount = ins:Get();
				elseif header == 0x10000AC2 then -- Binds on acquire ?
					result.itemBindOnAcquire = ins:Get();
				elseif 	header == 0x1000132C then	-- durability
					result.itemDurability = ins:GetLongLE();
				elseif header == 0x10000835 then	-- worth
					result.itemWorth = ins:GetLongLE();
				elseif header == 0x10000E7B then	-- quantity
					result.itemQuantity = ins:GetLongLE();
				elseif header == 0x0000034E then -- storage info
					result.itemStorageInfo = ins:GetLongLE();
				elseif header == 0x10001042 then -- LI 2nd range of DPS
					result.liMaxHit = ins:GetLongLE();
				elseif header == 0x10000ACD then -- dye info
					result.itemDye = ins:GetLongLE();
				elseif header == 0x10000570 then -- armour
					result.itemArmour = ins:GetLongLE();
				end
			end
		elseif header == 0x10000421 then
			-- GID, got that already
			ins:Consume(4);
		elseif header == 0x10002897 then
			-- IID, got that already
			ins:Consume(8);
		end
	end

	return result;
end