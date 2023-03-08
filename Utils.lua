function GetHex(IN)
    local B, K, OUT, I, D = 16, "0123456789ABCDEF", "", 0, 0;
    if IN == 0 or IN == "0" then return "00" end

    while IN > 0 do
        I = I + 1
        IN, D = math.floor(IN / B), math.mod(IN, B) + 1
        OUT = string.sub(K, D, D) .. OUT
    end

    if string.len(OUT) == 1 then OUT = "0" .. OUT end

    return OUT
end

function GetItemFromHex(itemHex)
    if (itemHex == nil) then
        return nil;
    end

    local cItemInspect = Turbine.UI.Lotro.Quickslot();
    cItemInspect:SetSize(1, 1);
    cItemInspect:SetVisible(false);

    local function SetItemShortcut()
        cItemInspect:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Item, "0x0," .. itemHex));
    end

    if pcall(SetItemShortcut) then
        SetItemShortcut();
        local item = cItemInspect:GetShortcut():GetItem();
        cItemInspect = nil;
        return item;
    end

    cItemInspect = nil;
end

function FilterLootTrackerListPeriod(list, period)
    local now = Turbine.Engine.GetLocalTime();
    local filteredList = {};

    for _, d in pairs(list) do
        if (d and d.time and now - d.time < period) then
            table.insert(filteredList, d);
        end
    end

    return filteredList;
end

function TimeAgo(startTime)
    if (startTime == nil) then
        return "";
    end

    local time = Turbine.Engine.GetLocalTime() - startTime;
    local days, hours = math.modf(time / ONE_DAY_IN_SECONDS);
    local hours, minutes = math.modf(hours * 24);
    local minutes, seconds = math.modf(minutes * 60);
    local seconds = math.floor(seconds * 60);

    if (days >= 1) then
        return days .. (days > 1 and " days " or " day ") .. "ago";
    elseif (hours >= 1) then
        return hours .. (hours > 1 and " hours " or " hour ") .. "ago";
    elseif (minutes >= 1) then
        return minutes .. (minutes > 1 and " minutes " or " minute ") .. "ago";
    elseif (seconds >= 1) then
        return seconds .. (seconds > 1 and " seconds " or " second ") .. "ago";
    end

    return "just now";
end
