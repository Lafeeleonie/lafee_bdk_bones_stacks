local _, NS = ...

NS.DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, nested in pairs(value) do result[key] = Copy(nested) end
    return result
end

NS.CopyTable = Copy

local function NewBoneShieldTracker()
    return {
        ID = "bone-shield",
        Enabled = true,
        Name = "Bone Shield",
        AuraIDs = { 195181 },
        Unit = "player",
        AuraFilter = "HELPFUL|PLAYER",
        AnchorMode = "CURSOR",
        AnchorFrame = "UIParent",
        AnchorPoint = "CENTER",
        RelativePoint = "CENTER",
        OffsetX = 18,
        OffsetY = -18,
        Font = NS.DEFAULT_FONT,
        FontSize = 28,
        FontFlags = "OUTLINE",
        TextColor = { 1, 1, 1 },
        HideWhenMissing = true,
        ShowDurationBar = false,
        DurationBarWidth = 42,
        DurationBarHeight = 3,
        DurationBarColor = { 0.2, 0.8, 1 },
    }
end

function NS:InitializeDatabase()
    LafeeBDKBonesStacksDB = type(LafeeBDKBonesStacksDB) == "table" and LafeeBDKBonesStacksDB or {}
    LafeeBDKBonesStacksDB.Version = 1
    LafeeBDKBonesStacksDB.Trackers = type(LafeeBDKBonesStacksDB.Trackers) == "table" and LafeeBDKBonesStacksDB.Trackers or {}
    LafeeBDKBonesStacksDB.Order = type(LafeeBDKBonesStacksDB.Order) == "table" and LafeeBDKBonesStacksDB.Order or {}
    LafeeBDKBonesStacksDB.MinimapButton = type(LafeeBDKBonesStacksDB.MinimapButton) == "table"
        and LafeeBDKBonesStacksDB.MinimapButton or { hide = false, minimapPos = 225 }
    self.db = LafeeBDKBonesStacksDB
    if next(self.db.Trackers) == nil then
        local tracker = NewBoneShieldTracker()
        self.db.Trackers[tracker.ID] = tracker
        self.db.Order[1] = tracker.ID
    end
    for _, tracker in pairs(self.db.Trackers) do
        if tracker.ShowDurationBar == nil then tracker.ShowDurationBar = false end
        if tracker.DurationBarWidth == nil then tracker.DurationBarWidth = 42 end
        if tracker.DurationBarHeight == nil then tracker.DurationBarHeight = 3 end
        if type(tracker.DurationBarColor) ~= "table" then tracker.DurationBarColor = { 0.2, 0.8, 1 } end
    end
end

function NS:GetTracker(id)
    return self.db and self.db.Trackers and self.db.Trackers[id] or nil
end

function NS:GetFirstTrackerID()
    return self.db and self.db.Order and self.db.Order[1] or nil
end

function NS:CreateTracker(name)
    local serial = 1
    local id
    repeat
        id = "tracker-" .. serial
        serial = serial + 1
    until not self.db.Trackers[id]
    local tracker = NewBoneShieldTracker()
    tracker.ID = id
    tracker.Name = name or "Aura Stacks"
    tracker.AuraIDs = {}
    tracker.AnchorMode = "FIXED"
    tracker.OffsetX = 0
    tracker.OffsetY = 0
    self.db.Trackers[id] = tracker
    self.db.Order[#self.db.Order + 1] = id
    return tracker
end

function NS:DuplicateTracker(id)
    local source = self:GetTracker(id)
    if not source then return nil end
    local copy = self:CreateTracker((source.Name or "Aura Stacks") .. " Copy")
    local copied = Copy(source)
    copied.ID = copy.ID
    copied.Name = (source.Name or "Aura Stacks") .. " Copy"
    self.db.Trackers[copy.ID] = copied
    return copied
end

function NS:DeleteTracker(id)
    if not self:GetTracker(id) then return false end
    self.db.Trackers[id] = nil
    for index, value in ipairs(self.db.Order) do
        if value == id then table.remove(self.db.Order, index) break end
    end
    return true
end

function NS:NormalizeAuraIDs(text)
    local result, seen = {}, {}
    for value in tostring(text or ""):gmatch("%d+") do
        local auraID = tonumber(value)
        if auraID and auraID > 0 and not seen[auraID] then
            seen[auraID] = true
            result[#result + 1] = auraID
        end
    end
    return result
end

function NS:AuraIDsToText(tracker)
    local parts = {}
    for index, auraID in ipairs(tracker.AuraIDs or {}) do parts[index] = tostring(auraID) end
    return table.concat(parts, ", ")
end
