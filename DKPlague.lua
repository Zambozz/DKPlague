local addonName = ...

----------------------------------------------------
-- Defaults
----------------------------------------------------

local defaults = {
    x = 0,
    y = -150,
    width = 36,
    height = 36,
	locked = false,
}

----------------------------------------------------
-- Main Frame
----------------------------------------------------

local frame = CreateFrame("Frame", "DKPlagueFrame", UIParent)

local diseases = {
    {
        name = "Frost Fever",
        icon = "Interface\\Icons\\Spell_DeathKnight_FrostFever"
    },
    {
        name = "Blood Plague",
        icon = "Interface\\Icons\\Spell_DeathKnight_BloodPlague"
    }
}

local icons = {}

----------------------------------------------------
-- Save Position
----------------------------------------------------

local function SavePosition()

    local point, _, relativePoint, x, y = frame:GetPoint()

    DKPlagueDB.x = floor(x)
    DKPlagueDB.y = floor(y)

end

----------------------------------------------------
-- Apply Settings
----------------------------------------------------

local function ApplySettings()

    frame:ClearAllPoints()
    frame:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        DKPlagueDB.x,
        DKPlagueDB.y
    )

    for i = 1, #diseases do

        icons[i]:SetWidth(DKPlagueDB.width)
        icons[i]:SetHeight(DKPlagueDB.height)

    end

    frame:SetWidth((DKPlagueDB.width * 2) + 8)
    frame:SetHeight(DKPlagueDB.height)

end

----------------------------------------------------
-- Reset Settings
----------------------------------------------------

local function ResetSettings()

    DKPlagueDB.x = defaults.x
    DKPlagueDB.y = defaults.y
    DKPlagueDB.width = defaults.width
    DKPlagueDB.height = defaults.height

    ApplySettings()

end

----------------------------------------------------
-- Draggable
----------------------------------------------------

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", function(self)

    if DKPlagueDB.locked then
        return
    end

    self:StartMoving()

end)

frame:SetScript("OnDragStop", function(self)

    self:StopMovingOrSizing()
    SavePosition()

end)

----------------------------------------------------
-- Icons
----------------------------------------------------

for index, disease in ipairs(diseases) do

    local icon = CreateFrame("Frame", nil, frame)

    if index == 1 then
        icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
    else
        icon:SetPoint("LEFT", icons[index - 1], "RIGHT", 8, 0)
    end

    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.texture:SetTexture(disease.icon)
    icon.texture:SetAlpha(0.3)

    icon.timer = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    icon.timer:SetPoint("CENTER", icon, "CENTER", 0, 0)

    icons[index] = icon

end

----------------------------------------------------
-- Disease Search
----------------------------------------------------

local function FindDisease(name)

    for i = 1, 40 do

        local debuffName,
              rank,
              texture,
              count,
              debuffType,
              duration,
              expirationTime,
              caster = UnitDebuff("target", i)

        if not debuffName then
            break
        end

        if debuffName == name and caster == "player" then
            return duration, expirationTime
        end

    end

    return nil

end

----------------------------------------------------
-- Update
----------------------------------------------------

local updateElapsed = 0

frame:SetScript("OnUpdate", function(self, elapsed)

    updateElapsed = updateElapsed + elapsed

    if updateElapsed < 0.1 then
        return
    end

    updateElapsed = 0

    if not UnitExists("target") then

        for i = 1, #diseases do

            icons[i].texture:SetAlpha(0.3)
            icons[i].timer:SetText("")

        end

        return

    end

    for i, disease in ipairs(diseases) do

    local duration, expirationTime =
        FindDisease(disease.name)

    if expirationTime then

        local remain = expirationTime - GetTime()

        if remain < 0 then
            remain = 0
        end

        icons[i].texture:SetAlpha(1)
        icons[i].timer:SetText(string.format("%.0f", remain))

    else

        icons[i].texture:SetAlpha(0.3)
        icons[i].timer:SetText("")

    end
end

end)

----------------------------------------------------
-- Options Panel
----------------------------------------------------

local options = CreateFrame(
    "Frame",
    "DKPlagueOptions",
    InterfaceOptionsFramePanelContainer
)

options.name = "DK Plague"

InterfaceOptions_AddCategory(options)

----------------------------------------------------
-- Title
----------------------------------------------------

local title = options:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontNormalLarge"
)

title:SetPoint("TOPLEFT", 16, -16)
title:SetText("DK Plague")

----------------------------------------------------
-- Slider Helper
----------------------------------------------------

local function CreateSlider(parent, name, minVal, maxVal)

    local slider = CreateFrame(
        "Slider",
        name,
        parent,
        "OptionsSliderTemplate"
    )

    slider:SetWidth(250)

    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)

    _G[name.."Low"]:SetText(minVal)
    _G[name.."High"]:SetText(maxVal)
    _G[name.."Text"]:SetText("")

    slider.valueText = slider:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )

    slider.valueText:SetPoint(
        "TOP",
        slider,
        "BOTTOM",
        0,
        -2
    )

    return slider

end

----------------------------------------------------
-- Reset Button
----------------------------------------------------

local resetBtn = CreateFrame(
    "Button",
    nil,
    options,
    "UIPanelButtonTemplate"
)

resetBtn:SetWidth(140)
resetBtn:SetHeight(24)

resetBtn:SetPoint(
    "TOPLEFT",
    title,
    "BOTTOMLEFT",
    0,
    -20
)

resetBtn:SetText("Reset Position")


local lockCheck = CreateFrame(
    "CheckButton",
    "DKPlagueLockCheck",
    options,
    "UICheckButtonTemplate"
)

lockCheck:SetPoint(
    "LEFT",
    resetBtn,
    "RIGHT",
    20,
    0
)

_G[lockCheck:GetName().."Text"]:SetText("Lock Frame")

lockCheck:SetScript("OnClick", function(self)

    DKPlagueDB.locked = self:GetChecked()

end)

----------------------------------------------------
-- Horizontal
----------------------------------------------------

local hSlider = CreateSlider(
    options,
    "DKPlagueHorizontalSlider",
    -1000,
    1000
)

hSlider:SetPoint(
    "TOPLEFT",
    resetBtn,
    "BOTTOMLEFT",
    0,
    -50
)

----------------------------------------------------
-- Vertical
----------------------------------------------------

local vSlider = CreateSlider(
    options,
    "DKPlagueVerticalSlider",
    -600,
    600
)

vSlider:SetPoint(
    "TOPLEFT",
    hSlider,
    "BOTTOMLEFT",
    0,
    -60
)

----------------------------------------------------
-- Width
----------------------------------------------------

local widthSlider = CreateSlider(
    options,
    "DKPlagueWidthSlider",
    20,
    100
)

widthSlider:SetPoint(
    "TOPLEFT",
    vSlider,
    "BOTTOMLEFT",
    0,
    -60
)

----------------------------------------------------
-- Height
----------------------------------------------------

local heightSlider = CreateSlider(
    options,
    "DKPlagueHeightSlider",
    20,
    100
)

heightSlider:SetPoint(
    "TOPLEFT",
    widthSlider,
    "BOTTOMLEFT",
    0,
    -60
)

----------------------------------------------------
-- Events
----------------------------------------------------

hSlider:SetScript("OnValueChanged", function(self, value)

    value = floor(value)

    DKPlagueDB.x = value
    self.valueText:SetText(value)

    ApplySettings()

end)

vSlider:SetScript("OnValueChanged", function(self, value)

    value = floor(value)

    DKPlagueDB.y = value
    self.valueText:SetText(value)

    ApplySettings()

end)

widthSlider:SetScript("OnValueChanged", function(self, value)

    value = floor(value)

    DKPlagueDB.width = value
    self.valueText:SetText(value)

    ApplySettings()

end)

heightSlider:SetScript("OnValueChanged", function(self, value)

    value = floor(value)

    DKPlagueDB.height = value
    self.valueText:SetText(value)

    ApplySettings()

end)

resetBtn:SetScript("OnClick", function()

    ResetSettings()

    hSlider:SetValue(DKPlagueDB.x)
    vSlider:SetValue(DKPlagueDB.y)
    widthSlider:SetValue(DKPlagueDB.width)
    heightSlider:SetValue(DKPlagueDB.height)

end)

----------------------------------------------------
-- Login
----------------------------------------------------

frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function()

    DKPlagueDB = DKPlagueDB or {}

    for k, v in pairs(defaults) do

        if DKPlagueDB[k] == nil then
            DKPlagueDB[k] = v
        end

    end

    ApplySettings()

    hSlider:SetValue(DKPlagueDB.x)
    vSlider:SetValue(DKPlagueDB.y)
    widthSlider:SetValue(DKPlagueDB.width)
    heightSlider:SetValue(DKPlagueDB.height)

    hSlider.valueText:SetText(DKPlagueDB.x)
    vSlider.valueText:SetText(DKPlagueDB.y)
    widthSlider.valueText:SetText(DKPlagueDB.width)
    heightSlider.valueText:SetText(DKPlagueDB.height)

end)

----------------------------------------------------
-- Maybe sone other spells in future?
----------------------------------------------------