local _, NS = ...

local locale = type(GetLocale) == "function" and GetLocale() or "enUS"

local overrides = {
    enUS = {
        TITLE = "Lafee BDK Bones Stacks",
        AURA_DURATION_DESC = "Choose a bar below the number or a radial duration indicator around the cursor.",
        PROGRESS_DISPLAY = "Duration indicator",
        OPEN_MENU = "Open Lafee BDK Bones Stacks",
    },
    frFR = {
        TITLE = "Lafee BDK Bones Stacks",
        TRACKERS = "Auras",
        AURA_TRACKERS = "Suivi des auras",
        TRACKER_SETTINGS = "Réglages du suivi",
        AURA_DURATION_DESC = "Choisissez une barre sous le nombre ou un indicateur radial de durée autour du curseur.",
        PROGRESS_DISPLAY = "Indicateur de durée",
        PROGRESS_COLOUR = "Couleur de l’indicateur",
        OPEN_MENU = "Ouvrir Lafee BDK Bones Stacks",
        AURA_STACKS = "Charges de l’aura",
    },
}

for key, value in pairs(overrides[locale] or {}) do
    NS.L[key] = value
end
