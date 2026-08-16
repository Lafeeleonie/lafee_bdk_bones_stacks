local _, NS = ...

local DATA_OBJECT_NAME = "LafeeBDKBonesStacks"
local ICON_TEXTURE = "Interface\\Icons\\ability_deathknight_boneshield"

local function GetSettings()
    if not NS.db then return nil end
    local settings = NS.db.MinimapButton or {}
    NS.db.MinimapButton = settings
    if settings.hide == nil then settings.hide = false end
    if settings.minimapPos == nil then settings.minimapPos = 225 end
    return settings
end

local function GetLibraries()
    if not LibStub then return nil end
    return LibStub("LibDataBroker-1.1", true), LibStub("LibDBIcon-1.0", true)
end

local function CreateDataObject(dataBroker)
    if NS.MinimapDataObject then return NS.MinimapDataObject end
    NS.MinimapDataObject = dataBroker:NewDataObject(DATA_OBJECT_NAME, {
        type = "launcher",
        icon = ICON_TEXTURE,
        OnClick = function(_, button)
            if button == "LeftButton" then NS:ToggleSettings() end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(NS.L.TITLE)
            tooltip:AddLine("Left-click to open settings.", 1, 1, 1)
        end,
    })
    return NS.MinimapDataObject
end

function NS:UpdateMinimapButton()
    local settings = GetSettings()
    local dataBroker, dbIcon = GetLibraries()
    if not settings or not dataBroker or not dbIcon then return end
    if not dbIcon:IsRegistered(DATA_OBJECT_NAME) then
        dbIcon:Register(DATA_OBJECT_NAME, CreateDataObject(dataBroker), settings)
    end
    if settings.hide then dbIcon:Hide(DATA_OBJECT_NAME) else dbIcon:Show(DATA_OBJECT_NAME) end
end

function NS:SetupMinimapButton()
    self:UpdateMinimapButton()
end
