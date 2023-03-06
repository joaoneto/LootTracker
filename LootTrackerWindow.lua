import "Turbine";
import "Turbine.UI";
import "Turbine.UI.Lotro";

LootTrackerWindow = class(Turbine.UI.Lotro.Window);

function LootTrackerWindow:Constructor()
	Turbine.UI.Lotro.Window.Constructor(self);

    self.list = {};

    self:SetSize(500, 420);
    self:SetText("LootTracker");

    self.verticalScrollbar = Turbine.UI.Lotro.ScrollBar();
    self.verticalScrollbar:SetOrientation(Turbine.UI.Orientation.Vertical);
    self.verticalScrollbar:SetParent(self);
    self.verticalScrollbar:SetZOrder(1);
    self.verticalScrollbar:SetPosition(500 - 20, 40);
    self.verticalScrollbar:SetSize(10, 420 - 60);

    self.list = Turbine.UI.ListBox();
    self.list:SetParent(self);
    self.list:SetPosition(20, 40);
    self.list:SetSize(500 - 40, 420 - 60);
    self.list:SetVerticalScrollBar(self.verticalScrollbar);

    self:Update();
end

function LootTrackerWindow:Update()
    while self.list:GetItemCount() > 0 do
        self.list:RemoveItemAt(1);
	end

    for _, data in pairs(_G.lootTrackerHistory) do
        local item = LootTrackerItem(data);
        if (item.inspect:GetItemInfo()) then
            item:SetParent(self);
            self.list:AddItem(item);
        end
    end
end