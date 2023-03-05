import "Turbine";
import "Turbine.UI";
import "Turbine.UI.Lotro";
import "Turbine.Gameplay";

ItemInspect = class(Turbine.UI.Lotro.ItemInfoControl);

function ItemInspect:Constructor(itemHex)
    Turbine.UI.Lotro.ItemInfoControl.Constructor(self);

    self:SetSize(36, 36);
    self:SetAllowDrop(false);
    self:SetVisible(true);
    self:SetQuantity(1);

    if itemHex then
        self:SetInfoId(itemHex);
    end
end

function ItemInspect:SetInfoId(itemHex)
    local itemInfo = GetItemFromHex(itemHex);

    if (itemInfo and itemInfo:GetItemInfo()) then
        self:SetItemInfo(itemInfo:GetItemInfo());
    end
end
