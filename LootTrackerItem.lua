import "Turbine";
import "Turbine.UI";
import "Turbine.UI.Lotro";

LootTrackerItem = class(Turbine.UI.Control);

local NEXT_UPDATE_IN_SECONDS = 10;

function GetQualityColor(quality)
    if (quality == Turbine.Gameplay.ItemQuality.Common) then
        return Turbine.UI.Color.White;
    elseif (quality == Turbine.Gameplay.ItemQuality.Incomparable) then
        return Turbine.UI.Color.Aqua;
    elseif (quality == Turbine.Gameplay.ItemQuality.Legendary) then
        return Turbine.UI.Color.Orange;
    elseif (quality == Turbine.Gameplay.ItemQuality.Rare) then
        return Turbine.UI.Color.Fuchsia;
    elseif (quality == Turbine.Gameplay.ItemQuality.Uncommon) then
        return Turbine.UI.Color.Yellow;
    end
end

function LootTrackerItem:Constructor(data)
    Turbine.UI.Control.Constructor(self);
    self:SetSize(500 - 40, 44);

    self.data = data;
    self.timeAgo = Turbine.UI.Label();
    self.description = Turbine.UI.Label();
    self.user = Turbine.UI.Label();

    self.inspect = ItemInspect(data.id);
    self.inspect:SetParent(self);
    self.inspect:SetPosition(0, 6);

    if (self.inspect:GetItemInfo()) then
        self.description:SetParent(self);
        self.description:SetPosition(42, 4);
        self.description:SetSize(200, 40);
        self.description:SetFont(Turbine.UI.Lotro.Font.TrajanPro14);
        self.description:SetForeColor(GetQualityColor(self.inspect:GetItemInfo():GetQuality()));
        self.description:SetOutlineColor(Turbine.UI.Color.Black);
        self.description:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
        self.description:SetText(self.inspect:GetItemInfo():GetName());

        self.timeAgo:SetParent(self);
        self.timeAgo:SetSize(120, 36);
        self.timeAgo:SetPosition(200 + 40 + 4, 4);
        self.timeAgo:SetFont(Turbine.UI.Lotro.Font.TrajanPro14);
        self.timeAgo:SetOutlineColor(Turbine.UI.Color.Black);
        self.timeAgo:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
        self.timeAgo:SetText(TimeAgo(data.time));

        self.user:SetParent(self);
        self.user:SetSize(120, 36);
        self.user:SetPosition(200 + 40 + 120 + 4 + 4, 4);
        self.user:SetFont(Turbine.UI.Lotro.Font.TrajanPro14);
        self.user:SetOutlineColor(Turbine.UI.Color.Black);
        self.user:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
        self.user:SetSelectable(true);
        self.user:SetText(data.user);
    end

    self.updateControl = Turbine.UI.Control();
    self.nextUpdateTime = Turbine.Engine.GetGameTime() + NEXT_UPDATE_IN_SECONDS;

    self.updateControl.Update = function ()
        if (Turbine.Engine.GetGameTime() > self.nextUpdateTime) then
            self.nextUpdateTime = Turbine.Engine.GetGameTime() + NEXT_UPDATE_IN_SECONDS;
            self:Update();
        end
    end

    -- todo: toggle timer updates
    self.updateControl:SetWantsUpdates(true);
end

function LootTrackerItem:Update()
    self.timeAgo:SetText(TimeAgo(self.data.time));
end
