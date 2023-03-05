import "Turbine";
import "LootTracker";

local lootWindow = LootTrackerWindow();

function HandleReceivedMessage(sender, args)
    if (args.ChatType == Turbine.ChatType.Say and args.Message:match("<Examine:IIDDID:")) then
        local id = args.Message:gsub("^(.*)%<Examine:IIDDID:(.*):(.*)%>%[(.*)%]%<(.*)%>(.*)\n$", "%3");
        -- Turbine.Shell.WriteLine("> " .. id);

        table.insert(_G.lootTrackerHistory, 1, {
            id = id,
            -- name = name,
            user = "Anamiri",
            time = Turbine.Engine.GetLocalTime(),
        });
        lootWindow:Update();
    end

    if (args.ChatType == Turbine.ChatType.FellowLoot and args.Message:match("<Examine:IIDDID:")) then
        local id = args.Message:gsub("(%w+) has acquired %<Examine:IIDDID:(.*):(.*)%>%[(.*)%](.*)\n", "%3");
        -- local name = args.Message:gsub("(%w+) has acquired (.*)%[(.*)%](.*)\n", "%3");
        local user = args.Message:gsub("(%w+) has acquired (.*)%[(.*)%](.*)\n", "%1");
        -- Turbine.Shell.WriteLine("> " .. user .. " loot " .. name);
        table.insert(_G.lootTrackerHistory, 1, {
            id = id,
            -- name = name,
            user = user,
            time = Turbine.Engine.GetLocalTime(),
        });
        lootWindow:Update();
	end
end

Turbine.Chat.Received = HandleReceivedMessage;

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
