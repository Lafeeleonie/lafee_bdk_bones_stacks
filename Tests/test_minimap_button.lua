local NS = { db = { MinimapButton = { hide = false, minimapPos = 225 } } }
local registered, visible, dataObject

local dataBroker = {
    NewDataObject = function(_, _, object)
        dataObject = object
        return object
    end,
}

local dbIcon = {
    IsRegistered = function() return registered == true end,
    Register = function(_, _, _, settings)
        registered = settings
    end,
    Show = function() visible = true end,
    Hide = function() visible = false end,
}

LibStub = function(name)
    if name == "LibDataBroker-1.1" then return dataBroker end
    if name == "LibDBIcon-1.0" then return dbIcon end
end

assert(loadfile("MinimapButton.lua") or loadfile("../MinimapButton.lua"))("lafee_bdk_bones_stacks", NS)
NS:SetupMinimapButton()
assert(registered == NS.db.MinimapButton and visible == true)
assert(dataObject and dataObject.type == "launcher")
assert(dataObject.icon == "Interface\\Icons\\ability_deathknight_boneshield")

NS.db.MinimapButton.hide = true
NS:UpdateMinimapButton()
assert(visible == false)

print("lafee bdk bones stacks minimap button tests passed")
