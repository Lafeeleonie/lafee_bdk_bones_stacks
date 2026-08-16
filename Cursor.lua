local _, NS = ...

local Cursor = { active = {}, count = 0 }
NS.Cursor = Cursor

local updater = CreateFrame("Frame")
updater:Hide()

local function UpdateCursorTrackers()
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    if not scale or scale == 0 then return end
    cursorX = cursorX / scale
    cursorY = cursorY / scale
    for _, runtime in pairs(Cursor.active) do
        local tracker = runtime.tracker
        local x = cursorX + (tonumber(tracker.OffsetX) or 0)
        local y = cursorY + (tonumber(tracker.OffsetY) or 0)
        if runtime.cursorX ~= x or runtime.cursorY ~= y then
            runtime.cursorX, runtime.cursorY = x, y
            runtime.root:ClearAllPoints()
            runtime.root:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
        end
    end
end

updater:SetScript("OnUpdate", UpdateCursorTrackers)

function Cursor:Add(runtime)
    if runtime.cursorActive then return end
    runtime.cursorActive = true
    runtime.cursorX, runtime.cursorY = nil, nil
    self.active[runtime.id] = runtime
    self.count = self.count + 1
    if self.count == 1 then updater:Show() end
end

function Cursor:Remove(runtime)
    if not runtime.cursorActive then return end
    runtime.cursorActive = nil
    self.active[runtime.id] = nil
    self.count = self.count - 1
    if self.count <= 0 then
        self.count = 0
        updater:Hide()
    end
end

function Cursor:GetActiveCount()
    return self.count
end
