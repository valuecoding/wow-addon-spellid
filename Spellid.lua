local Spellid = CreateFrame("Frame")

-- Standardeinstellungen
local defaults = {
    showSpellID = true,
    showIconID = true
}

-- Initialisierung der Einstellungen
local function deepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = deepCopy(v)
    end
    return copy
end

-- Fallback falls CopyTable in der Client-Version nicht vorhanden ist
local copyTableFunc = CopyTable or deepCopy

SpellidDB = SpellidDB or copyTableFunc(defaults)

local function resetTooltipFlags(tooltip)
    tooltip.hasSpellData = false
    tooltip.hasItemData = false
end

-- Abstraktion, da C_Spell in älteren Clients nicht existiert
local function GetSpellIconTexture(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    end
    -- Fallback über GetSpellTexture (Classic) oder GetSpellInfo
    return (GetSpellTexture and GetSpellTexture(spellID)) or select(3, GetSpellInfo(spellID))
end

local function addSpellInfo(tooltip)
    if tooltip.hasSpellData then return end
    local _, spellID = tooltip:GetSpell()
    if spellID then
        local icon = GetSpellIconTexture(spellID)
        
        if SpellidDB.showSpellID then
            if icon then
                tooltip:AddLine("|T" .. icon .. ":0|t Spell ID: " .. spellID, 1, 1, 1)
            else
                tooltip:AddLine("Spell ID: " .. spellID, 1, 1, 1)
            end
        end
        
        if icon and SpellidDB.showIconID then
            tooltip:AddLine("|T" .. icon .. ":0|t Icon ID: " .. icon, 1, 1, 1)
        end
        
        if (SpellidDB.showSpellID or SpellidDB.showIconID) then
            tooltip:Show()
        end
        tooltip.hasSpellData = true
    end
end

local function addItemInfo(tooltip)
    if tooltip.hasItemData then return end
    local _, link = tooltip:GetItem()
    if link then
        local itemID = string.match(link, "item:(%d+)")
        if itemID then
            local icon = select(10, GetItemInfo(itemID))
            
            if SpellidDB.showSpellID then
                if icon then
                    tooltip:AddLine("|T" .. icon .. ":0|t Item ID: " .. itemID, 1, 1, 1)
                else
                    tooltip:AddLine("Item ID: " .. itemID, 1, 1, 1)
                end
            end
            
            if icon and SpellidDB.showIconID then
                tooltip:AddLine("|T" .. icon .. ":0|t Icon ID: " .. icon, 1, 1, 1)
            end
            
            if (SpellidDB.showSpellID or SpellidDB.showIconID) then
                tooltip:Show()
            end
            tooltip.hasItemData = true
        end
    end
end

local function onTooltipUpdate(tooltip)
    addSpellInfo(tooltip)
    addItemInfo(tooltip)
end

local function onTooltipShow(tooltip)
    resetTooltipFlags(tooltip)
end

-- Einfaches Einstellungsfenster
local optionsFrame = nil

local function CreateOptionsFrame()
    if optionsFrame then return optionsFrame end
    
    -- Hauptframe erstellen
    optionsFrame = CreateFrame("Frame", "SpellidOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(300, 150)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    optionsFrame:Hide()
    
    -- Titel
    optionsFrame.title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    optionsFrame.title:SetPoint("TOP", optionsFrame, "TOP", 0, -5)
    optionsFrame.title:SetText("Spellid Options")
    
    -- Spell ID Checkbox
    optionsFrame.spellIDCheckbox = CreateFrame("CheckButton", "SpellidShowSpellIDCheckbox", optionsFrame, "UICheckButtonTemplate")
    optionsFrame.spellIDCheckbox:SetPoint("TOPLEFT", 20, -40)
    optionsFrame.spellIDCheckbox.text:SetText("Show Spell/Item ID")
    optionsFrame.spellIDCheckbox:SetChecked(SpellidDB.showSpellID)
    optionsFrame.spellIDCheckbox:SetScript("OnClick", function(self)
        SpellidDB.showSpellID = self:GetChecked()
    end)
    
    -- Icon ID Checkbox
    optionsFrame.iconIDCheckbox = CreateFrame("CheckButton", "SpellidShowIconIDCheckbox", optionsFrame, "UICheckButtonTemplate")
    optionsFrame.iconIDCheckbox:SetPoint("TOPLEFT", 20, -70)
    optionsFrame.iconIDCheckbox.text:SetText("Show Icon ID")
    optionsFrame.iconIDCheckbox:SetChecked(SpellidDB.showIconID)
    optionsFrame.iconIDCheckbox:SetScript("OnClick", function(self)
        SpellidDB.showIconID = self:GetChecked()
    end)
    
    -- Schließen-Button
    optionsFrame.closeButton = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    optionsFrame.closeButton:SetSize(100, 25)
    optionsFrame.closeButton:SetPoint("BOTTOM", 0, 15)
    optionsFrame.closeButton:SetText("Close")
    optionsFrame.closeButton:SetScript("OnClick", function()
        optionsFrame:Hide()
    end)
    
    return optionsFrame
end

-- Slash-Befehle
SLASH_SPELLID1 = "/spellid"
SlashCmdList["SPELLID"] = function(msg)
    msg = msg:lower()
    
    if msg == "spellid" or msg == "spell" then
        SpellidDB.showSpellID = not SpellidDB.showSpellID
        print("Spellid: " .. (SpellidDB.showSpellID and "Spell IDs enabled" or "Spell IDs disabled"))
    elseif msg == "iconid" or msg == "icon" then
        SpellidDB.showIconID = not SpellidDB.showIconID
        print("Spellid: " .. (SpellidDB.showIconID and "Icon IDs enabled" or "Icon IDs disabled"))
    else
        -- Einstellungsfenster anzeigen
        local options = CreateOptionsFrame()
        options:Show()
    end
end

Spellid:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Flags vor jedem neuen Tooltip resetten
        GameTooltip:HookScript("OnShow", onTooltipShow)
        GameTooltip:HookScript("OnUpdate", onTooltipUpdate)
        GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
            resetTooltipFlags(tooltip)
        end)

        ItemRefTooltip:HookScript("OnShow", onTooltipShow)
        ItemRefTooltip:HookScript("OnUpdate", onTooltipUpdate)
        ItemRefTooltip:HookScript("OnTooltipCleared", function(tooltip)
            resetTooltipFlags(tooltip)
        end)
    end
end)

Spellid:RegisterEvent("PLAYER_ENTERING_WORLD")
