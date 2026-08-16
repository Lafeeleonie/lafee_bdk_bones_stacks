local _, NS = ...

local function ResolveFrame(name)
    if type(name) ~= "string" or name == "" then return UIParent end
    local frame = rawget(_G, name)
    if type(frame) == "table" and type(frame.GetObjectType) == "function" then return frame end
    return UIParent
end

function NS:ApplyAnchor(runtime)
    local tracker = runtime.tracker
    local root = runtime.root
    if not root or not tracker then return end
    if tracker.AnchorMode == "CURSOR" then
        self.Cursor:Add(runtime)
        return
    end
    self.Cursor:Remove(runtime)
    local parent = tracker.AnchorMode == "FRAME" and ResolveFrame(tracker.AnchorFrame) or UIParent
    root:ClearAllPoints()
    root:SetPoint(tracker.AnchorPoint or "CENTER", parent, tracker.RelativePoint or "CENTER",
        tonumber(tracker.OffsetX) or 0, tonumber(tracker.OffsetY) or 0)
end

function NS:RefreshAnchors()
    for _, runtime in pairs(self.Runtime or {}) do self:ApplyAnchor(runtime) end
end
