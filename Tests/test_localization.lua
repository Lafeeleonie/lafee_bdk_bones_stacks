local locales = { "enUS", "enGB", "frFR", "deDE", "esES", "esMX", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW" }
local required = {
    "TITLE", "SETTINGS", "GENERAL", "TRACKERS", "POSITIONING", "APPEARANCE",
    "SHOW_MINIMAP", "SAFE_AURA_DISPLAY", "AURA_TRACKERS", "TRACKER_SETTINGS",
    "NAME", "AURA_IDS", "UNIT", "ENABLED", "HIDE_WHEN_MISSING",
    "CURSOR_OFFSET", "OFFSET_X", "OFFSET_Y", "TEXT_APPEARANCE", "FONT",
    "TEXT_SIZE", "OUTLINE_LABEL", "TEXT_COLOUR", "AURA_DURATION",
    "PROGRESS_DISPLAY", "HORIZONTAL_BAR", "CIRCLE_AROUND_CURSOR",
    "BAR_WIDTH", "BAR_HEIGHT", "CIRCLE_SIZE", "CIRCLE_THICKNESS",
    "PROGRESS_COLOUR", "MINIMAP_TOOLTIP",
}

local function loadLocaleFile(fileName, NS)
    local chunk = loadfile("Locales/" .. fileName) or loadfile("../Locales/" .. fileName)
    assert(chunk)("addon", NS)
end

for _, locale in ipairs(locales) do
    local NS = {}
    GetLocale = function() return locale end
    loadLocaleFile("enUS.lua", NS)
    if locale ~= "enUS" and locale ~= "enGB" then loadLocaleFile(locale .. ".lua", NS) end
    loadLocaleFile("Loader.lua", NS)
    for _, key in ipairs(required) do
        assert(type(NS.L[key]) == "string" and NS.L[key] ~= "", locale .. " missing " .. key)
    end
end

print("localization tests passed")

