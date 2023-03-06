import "Turbine";
import "LootTracker";

local lootWindow = LootTrackerWindow();

function HandleReceivedMessage(sender, args)
    if (args.ChatType == Turbine.ChatType.FellowLoot and args.Message:match("<Examine:IIDDID:")) then
        local id = args.Message:gsub("(%w+) has acquired %<Examine:IIDDID:(.*):(.*)%>%[(.*)%](.*)\n", "%3");
        local user = args.Message:gsub("(%w+) has acquired (.*)%[(.*)%](.*)\n", "%1");

        table.insert(_G.lootTrackerHistory, 1, {
            id = id,
            user = user,
            time = Turbine.Engine.GetLocalTime(),
        });
        lootWindow:Update();
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
    table.sort(_G.lootTrackerHistory, function(a, b)
        return a.time > b.time;
    end);
    lootWindow:SetVisible(true);
    lootWindow:Update();
end

Plugins.LootTracker.Unload = function ()
    local filteredLootList = FilterLootTrackerListPeriod(_G.lootTrackerHistory, ONE_DAY_IN_SECONDS);
    Turbine.PluginData.Save(Turbine.DataScope.Account, "LootTracker", filteredLootList);
end
