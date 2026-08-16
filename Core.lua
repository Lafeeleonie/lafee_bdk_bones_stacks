local addonName, NS = ...

NS.addonName = addonName

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff79c2fflafee bdk bones stacks:|r " .. message)
end

function NS:RefreshAfterExternalAddon()
    self:RefreshAnchors()
    self:PreparePendingTrackers()
end

events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == addonName then
            NS:InitializeDatabase()
            NS:InitializeSettings()
            NS:RefreshAllTrackers()
            NS:SetupMinimapButton()
            SLASH_LAFEEBDKBONESSTACKS1 = "/las"
            SlashCmdList.LAFEEBDKBONESSTACKS = function(message)
                if message == "preview" then
                    local id = NS:GetFirstTrackerID()
                    if id then
                        local runtime = NS:EnsureTracker(id)
                        NS:SetPreview(id, not runtime.previewActive)
                    end
                else
                    NS:ToggleSettings()
                end
            end
        else
            NS:RefreshAfterExternalAddon()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        NS:PreparePendingTrackers()
        NS:RefreshAnchors()
    elseif event == "PLAYER_ENTERING_WORLD" then
        NS:RefreshAllTrackers()
    end
end)

NS.Print = Print
