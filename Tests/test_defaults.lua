local NS = {}
local defaults = loadfile("Defaults.lua") or loadfile("../Defaults.lua")
assert(defaults)("lafee_bdk_bones_stacks", NS)

LafeeBDKBonesStacksDB = nil
NS:InitializeDatabase()
local boneShield = NS:GetTracker("bone-shield")
assert(boneShield and boneShield.AuraIDs[1] == 195181)
assert(boneShield.Unit == "player")
assert(NS.db.MinimapButton.hide == false and NS.db.MinimapButton.minimapPos == 225)
assert(boneShield.ShowDurationBar == false)

local created = NS:CreateTracker("Test")
created.AuraIDs = NS:NormalizeAuraIDs("195181, 195181, 49039")
assert(#created.AuraIDs == 2)
local duplicate = NS:DuplicateTracker(created.ID)
assert(duplicate and duplicate.ID ~= created.ID and duplicate.AuraIDs[1] == 195181)
assert(NS:DeleteTracker(created.ID) == true)
assert(NS:GetTracker(created.ID) == nil)

print("lafee bdk bones stacks defaults tests passed")
