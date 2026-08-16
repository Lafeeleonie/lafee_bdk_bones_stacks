local _, NS = ...

NS.Runtime = {}

local StackFormatter

local function IsInCombat()
    return InCombatLockdown and InCombatLockdown() == true
end

local function Call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return false end
    return pcall(object[method], object, ...)
end

local function EnsureAuraContainerLoaded()
    if type(CustomAuraContainerSlotDefaultOptions) == "table" then return true end
    if IsInCombat() then return false end
    if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
        pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
    end
    return type(CustomAuraContainerSlotDefaultOptions) == "table"
end

local function GetStackFormatter()
    if StackFormatter then return StackFormatter end
    if C_StringUtil and type(C_StringUtil.CreateAbbreviatedNumberFormatter) == "function" then
        StackFormatter = C_StringUtil.CreateAbbreviatedNumberFormatter()
    end
    return StackFormatter
end

local function BuildCandidateFilters(tracker)
    local includeSpellIDs = {}
    local count = 0
    for _, auraID in ipairs(tracker.AuraIDs or {}) do
        if type(auraID) == "number" and auraID > 0 and not includeSpellIDs[auraID] then
            includeSpellIDs[auraID] = true
            count = count + 1
        end
    end
    if count == 0 then return nil end
    return { includeSpellIDs = includeSpellIDs }
end

local function ApplyTextStyle(runtime)
    local tracker, count = runtime.tracker, runtime.count
    if not count then return false end
    local font = tracker.Font or NS.DEFAULT_FONT
    local size = tonumber(tracker.FontSize) or 24
    local flags = tracker.FontFlags == "NONE" and "" or tracker.FontFlags or "OUTLINE"
    local colour = tracker.TextColor or { 1, 1, 1 }
    count:ClearAllPoints()
    count:SetPoint("CENTER", runtime.root, "CENTER", 0, 0)
    count:SetFont(font, size, flags)
    count:SetTextColor(colour[1] or 1, colour[2] or 1, colour[3] or 1, 1)
    return true
end

local function ApplyDurationBarStyle(runtime)
    local tracker, bar = runtime.tracker, runtime.durationBar
    if not bar then return false end
    local colour = tracker.DurationBarColor or { 0.2, 0.8, 1 }
    local width = math.max(12, tonumber(tracker.DurationBarWidth) or 42)
    local height = math.max(1, tonumber(tracker.DurationBarHeight) or 3)
    local fontSize = tonumber(tracker.FontSize) or 24
    bar:ClearAllPoints()
    bar:SetPoint("TOP", runtime.root, "CENTER", 0, -(fontSize * 0.5 + 3))
    bar:SetSize(width, height)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(colour[1] or 0.2, colour[2] or 0.8, colour[3] or 1, 1)
    return true
end

local function ConfigureDurationBar(runtime)
    local button, bar = runtime.button, runtime.durationBar
    if not button or not bar then return false end
    if runtime.tracker.ShowDurationBar then
        if not ApplyDurationBarStyle(runtime) then return false end
        bar:Show()
        return Call(button, "SetDurationBar", bar, {})
    end
    Call(button, "ClearDurationBar")
    bar:Hide()
    return true
end

local function CreateRoot(runtime)
    local root = CreateFrame("Frame", nil, UIParent)
    root:SetSize(1, 1)
    root:SetFrameStrata("HIGH")
    root:SetMovable(true)
    root:RegisterForDrag("LeftButton")
    root:EnableMouse(false)
    root:SetScript("OnDragStart", function(frame)
        if runtime.unlocked then frame:StartMoving() end
    end)
    root:SetScript("OnDragStop", function(frame)
        if not runtime.unlocked then return end
        frame:StopMovingOrSizing()
        local left, bottom = frame:GetLeft(), frame:GetBottom()
        if left and bottom then
            runtime.tracker.AnchorMode = "FIXED"
            runtime.tracker.OffsetX = left
            runtime.tracker.OffsetY = bottom
            NS:ApplyAnchor(runtime)
        end
    end)
    runtime.root = root
    runtime.preview = root:CreateFontString(nil, "OVERLAY")
    runtime.preview:SetPoint("CENTER", root, "CENTER", 0, 0)
    runtime.preview:Hide()
    runtime.previewDuration = CreateFrame("StatusBar", nil, root)
    runtime.previewDuration:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    runtime.previewDuration:SetMinMaxValues(0, 1)
    runtime.previewDuration:SetValue(0.65)
    runtime.previewDuration:Hide()
end

local function InitializeAuraButton(runtime, auraButton)
    runtime.button = auraButton
    if not Call(auraButton, "ClearAllPoints") or not Call(auraButton, "SetAllPoints", runtime.root)
        or not Call(auraButton, "SetMouseMotionEnabled", false) then
        return false
    end
    runtime.count = auraButton:CreateFontString(nil, "OVERLAY")
    runtime.durationBar = CreateFrame("StatusBar", nil, auraButton)
    if not ApplyTextStyle(runtime) then return false end
    local options = {}
    local formatter = GetStackFormatter()
    if formatter then options.formatter = formatter end
    return Call(auraButton, "SetApplicationCount", runtime.count, options) and ConfigureDurationBar(runtime)
end

local function CreateAuraDisplay(runtime)
    if IsInCombat() or not EnsureAuraContainerLoaded() then return false end
    local filters = BuildCandidateFilters(runtime.tracker)
    if not filters then return false end
    local container = CreateFrame("AuraContainer", nil, runtime.root, "CustomAuraContainerTemplate")
    container:SetAllPoints(runtime.root)
    container:SetUnit(runtime.tracker.Unit or "player")
    runtime.container = container
    local initialized = false
    local function InitializeFrame(auraButton)
        initialized = InitializeAuraButton(runtime, auraButton)
    end
    local ok, button = Call(container, "AddAuraSlot", "tracked", runtime.tracker.AuraFilter or "HELPFUL|PLAYER", {
        candidateFilters = filters,
        initializeFrame = InitializeFrame,
    })
    if not ok or not button or not initialized or not Call(container, "SetEnabled", true) then
        runtime.container = nil
        return false
    end
    return true
end

local function ReconfigureAuraDisplay(runtime)
    if not runtime.container or IsInCombat() then return false end
    local filters = BuildCandidateFilters(runtime.tracker)
    if not filters then
        Call(runtime.container, "SetEnabled", false)
        return false
    end
    if not Call(runtime.container, "SetUnit", runtime.tracker.Unit or "player")
        or not Call(runtime.container, "SetAuraSlotCandidateFilters", "tracked", filters)
        or not ApplyTextStyle(runtime) or not ConfigureDurationBar(runtime) then
        return false
    end
    Call(runtime.container, "SetEnabled", not runtime.previewActive)
    return true
end

function NS:EnsureTracker(id)
    local tracker = self:GetTracker(id)
    if not tracker then return nil end
    local runtime = self.Runtime[id]
    if runtime then
        runtime.tracker = tracker
        return runtime
    end
    runtime = { id = id, tracker = tracker }
    self.Runtime[id] = runtime
    CreateRoot(runtime)
    return runtime
end

function NS:RefreshTracker(id)
    local runtime = self:EnsureTracker(id)
    if not runtime then return end
    if not runtime.tracker.Enabled and not runtime.previewActive then
        self.Cursor:Remove(runtime)
        if runtime.container then Call(runtime.container, "SetEnabled", false) end
        runtime.root:Hide()
        return
    end
    runtime.root:Show()
    self:ApplyAnchor(runtime)
    if runtime.previewActive then
        self:SetPreview(id, true)
        return
    end
    if runtime.container then
        if not ReconfigureAuraDisplay(runtime) then runtime.pending = true end
    elseif not CreateAuraDisplay(runtime) then
        runtime.pending = true
    end
end

function NS:RefreshAllTrackers()
    for _, id in ipairs(self.db.Order or {}) do self:RefreshTracker(id) end
end

function NS:RemoveTrackerRuntime(id)
    local runtime = self.Runtime[id]
    if not runtime then return end
    self.Cursor:Remove(runtime)
    if runtime.root then runtime.root:Hide() end
    self.Runtime[id] = nil
end

function NS:SetPreview(id, enabled)
    local runtime = self:EnsureTracker(id)
    if not runtime or IsInCombat() then return false end
    runtime.previewActive = enabled == true
    if runtime.previewActive then
        self.Cursor:Remove(runtime)
        runtime.root:Show()
        runtime.preview:SetFont(runtime.tracker.Font or NS.DEFAULT_FONT, tonumber(runtime.tracker.FontSize) or 24,
            runtime.tracker.FontFlags == "NONE" and "" or runtime.tracker.FontFlags or "OUTLINE")
        local colour = runtime.tracker.TextColor or { 1, 1, 1 }
        runtime.preview:SetTextColor(colour[1] or 1, colour[2] or 1, colour[3] or 1, 1)
        runtime.preview:SetText("10")
        runtime.preview:Show()
        ApplyDurationBarStyle({ tracker = runtime.tracker, durationBar = runtime.previewDuration, root = runtime.root })
        runtime.previewDuration:SetShown(runtime.tracker.ShowDurationBar == true)
        if runtime.container then Call(runtime.container, "SetEnabled", false) end
        self:ApplyAnchor(runtime)
    else
        runtime.preview:Hide()
        runtime.previewDuration:Hide()
        if runtime.tracker.Enabled then self:RefreshTracker(id) else runtime.root:Hide() end
    end
    return true
end

function NS:ClearAllPreviews()
    for id, runtime in pairs(self.Runtime) do
        if runtime.previewActive then self:SetPreview(id, false) end
    end
end

function NS:ToggleUnlock(id)
    local runtime = self:EnsureTracker(id)
    if not runtime or IsInCombat() then return false end
    runtime.unlocked = not runtime.unlocked
    runtime.root:EnableMouse(runtime.unlocked)
    if runtime.unlocked then self:SetPreview(id, true) end
    return runtime.unlocked
end

function NS:PreparePendingTrackers()
    if IsInCombat() then return end
    for _, runtime in pairs(self.Runtime) do
        if runtime.pending then
            runtime.pending = nil
            self:RefreshTracker(runtime.id)
        end
    end
end
