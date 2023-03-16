import "Turbine";
import "LootTracker";

local lootWindow = LootTrackerWindow();

function HandleReceivedMessage(sender, args)
    local user = args.Message:match('(.*) has acquired');
    if (args.ChatType == Turbine.ChatType.FellowLoot or user) then
        local idHex = args.Message:match('has acquired <Examine:IIDDID:.*:(.*)>%b[]<\\Examine>');
        local infoStr = args.Message:match('has acquired <ExamineItemInstance:ItemInfo:(.*)>%b[]<\\ExamineItemInstance>');
        local id = (idHex and idHex) or (infoStr and "0x" .. GetHex(ItemLinkDecode.DecodeLinkData(infoStr, false).itemGID));
        local time = Turbine.Engine.GetLocalTime();
        local data = {
            id = id,
            user = user,
            time = time,
        };
        table.insert(_G.lootTrackerHistory, -1, data);
        lootWindow:AddItem(data);
    end
end

Turbine.Chat.Received = HandleReceivedMessage;

-- command
OpenLootTrackerWindow = Turbine.ShellCommand();

function OpenLootTrackerWindow:Execute(cmd, args)
    lootWindow:SetVisible(true);
end

Turbine.Shell.AddCommand("lt", OpenLootTrackerWindow);

-- load / unload
Plugins.LootTracker.Load = function ()
    local filteredLootList = Turbine.PluginData.Load(Turbine.DataScope.Account, "LootTracker");
    _G.lootTrackerHistory = FilterLootTrackerListPeriod(filteredLootList, ONE_DAY_IN_SECONDS);
    table.sort(_G.lootTrackerHistory, function (a, b)
        return a.time < b.time;
    end);
    lootWindow:SetVisible(true);
    lootWindow:LoadData(_G.lootTrackerHistory);
end

Plugins.LootTracker.Unload = function ()
    local filteredLootList = FilterLootTrackerListPeriod(_G.lootTrackerHistory, ONE_DAY_IN_SECONDS);
    Turbine.PluginData.Save(Turbine.DataScope.Account, "LootTracker", filteredLootList);
end
