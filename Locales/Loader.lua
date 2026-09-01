local _, addon = ...

local locales = addon.Locales or {}
local locale = type(GetLocale) == "function" and GetLocale() or "enUS"

if locale == "enGB" then
    locale = "enUS"
elseif locale == "esMX" and not locales.esMX then
    locale = "esES"
end

local fallback = locales.enUS or {}
local selected = locales[locale] or {}
addon.L = setmetatable(selected, { __index = fallback })
