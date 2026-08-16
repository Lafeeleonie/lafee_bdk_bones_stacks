local _, NS = ...

local SettingsWindow
local selectedID
local pages = {}
local navButtons = {}

local function Label(parent, text, font, x, y)
    local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 24)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function Edit(parent, label, key, x, y, width)
    Label(parent, label, "GameFontHighlight", x, y)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetAutoFocus(false)
    input:SetSize(width, 22)
    input:SetPoint("TOPLEFT", x + 220, y + 3)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return input, key
end

local function Dropdown(parent, label, x, y, width, choices, getValue, setValue)
    Label(parent, label, "GameFontHighlight", x, y)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", x + 205, y + 7)
    UIDropDownMenu_SetWidth(dropdown, width)
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        if level ~= 1 then return end
        for _, choice in ipairs(choices) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = choice.text
            info.value = choice.value
            info.func = function(_, value)
                setValue(value)
                UIDropDownMenu_SetSelectedValue(dropdown, value)
            end
            info.checked = getValue() == choice.value
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    function dropdown:Refresh()
        UIDropDownMenu_SetSelectedValue(self, getValue())
    end
    return dropdown
end

local function Slider(parent, label, x, y, width, minimum, maximum, step, getValue, setValue)
    Label(parent, label, "GameFontHighlight", x, y)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x + 205, y + 7)
    slider:SetWidth(width)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText(tostring(minimum))
    slider.High:SetText(tostring(maximum))
    slider.Text:Hide()
    slider.value = Label(parent, "", "GameFontHighlight", x + 215 + width, y)
    slider:SetScript("OnValueChanged", function(self, value)
        setValue(value)
        self.value:SetText(string.format("%.0f", value))
    end)
    slider:SetScript("OnMouseUp", function()
        if selectedID then NS:RefreshTracker(selectedID) end
    end)
    function slider:Refresh()
        local value = getValue()
        self:SetValue(value)
        self.value:SetText(string.format("%.0f", value))
    end
    return slider
end

local function ColourButton(parent, label, x, y, getValue, setValue)
    Label(parent, label, "GameFontHighlight", x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x + 205, y + 2)
    button:SetSize(56, 24)
    button:SetText("Colour")
    button.swatch = button:CreateTexture(nil, "OVERLAY")
    button.swatch:SetPoint("TOPLEFT", 4, -4)
    button.swatch:SetPoint("BOTTOMRIGHT", -4, 4)
    button:SetScript("OnClick", function()
        local r, g, b = unpack(getValue())
        local previous = { r = r, g = g, b = b }
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, hasOpacity = false,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                setValue({ nr, ng, nb })
                button:Refresh()
                NS:RefreshTracker(selectedID)
            end,
            cancelFunc = function()
                setValue({ previous.r, previous.g, previous.b })
                button:Refresh()
                NS:RefreshTracker(selectedID)
            end,
        })
    end)
    function button:Refresh()
        local colour = getValue()
        self.swatch:SetColorTexture(colour[1] or 1, colour[2] or 1, colour[3] or 1, 1)
    end
    return button
end

local function Section(parent, title, y)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetPoint("TOPLEFT", 12, y)
    bar:SetPoint("TOPRIGHT", -12, y)
    bar:SetHeight(42)
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    bar:SetBackdropColor(0.015, 0.015, 0.02, 0.92)
    Label(bar, title, "GameFontNormalLarge", 14, -11):SetTextColor(1, 0.82, 0)
    return y - 58
end

local function CurrentTracker()
    selectedID = NS:GetTracker(selectedID) and selectedID or NS:GetFirstTrackerID()
    return NS:GetTracker(selectedID)
end

local function OrderedTrackerID(offset)
    local order = NS.db.Order
    if #order == 0 then return nil end
    local current = 1
    for index, id in ipairs(order) do
        if id == selectedID then current = index break end
    end
    return order[((current - 1 + offset) % #order) + 1]
end

local function ParseColour(text)
    local result = {}
    for value in tostring(text or ""):gmatch("[%d%.]+") do result[#result + 1] = tonumber(value) end
    if #result ~= 3 then return nil end
    for index = 1, 3 do result[index] = math.max(0, math.min(1, result[index])) end
    return result
end

local function ApplyTrackerInputs(panel)
    local tracker = CurrentTracker()
    if not tracker then return end
    local inputs = panel.inputs
    tracker.Name = inputs.Name:GetText() ~= "" and inputs.Name:GetText() or tracker.Name
    tracker.AuraIDs = NS:NormalizeAuraIDs(inputs.AuraIDs:GetText())
    tracker.Unit = inputs.Unit:GetText() ~= "" and inputs.Unit:GetText() or "player"
    tracker.Enabled = panel.enabled:GetChecked() == true
    tracker.HideWhenMissing = panel.hideWhenMissing:GetChecked() == true
    NS:RefreshTracker(selectedID)
end

local function ApplyPositionInputs(panel)
    local tracker = CurrentTracker()
    if not tracker then return end
    tracker.AnchorFrame = panel.inputs.AnchorFrame:GetText() ~= "" and panel.inputs.AnchorFrame:GetText() or "UIParent"
    NS:RefreshTracker(selectedID)
end

local function ApplyAppearanceInputs(panel)
    local tracker = CurrentTracker()
    if not tracker then return end
    tracker.Font = panel.inputs.Font:GetText() ~= "" and panel.inputs.Font:GetText() or NS.DEFAULT_FONT
    tracker.FontSize = math.max(6, tonumber(panel.inputs.FontSize:GetText()) or 24)
    local flags = string.upper(panel.inputs.FontFlags:GetText() or "")
    tracker.FontFlags = (flags == "OUTLINE" or flags == "THICKOUTLINE") and flags or "NONE"
    tracker.TextColor = ParseColour(panel.inputs.TextColor:GetText()) or { 1, 1, 1 }
    NS:RefreshTracker(selectedID)
end

local function AddPage(name)
    local page = CreateFrame("Frame", nil, SettingsWindow.content)
    page:SetAllPoints()
    page:Hide()
    pages[name] = page
    return page
end

local function ShowPage(name)
    for pageName, page in pairs(pages) do page:SetShown(pageName == name) end
    for pageName, button in pairs(navButtons) do
        button.highlight:SetShown(pageName == name)
        button.label:SetTextColor(pageName == name and 1 or 0.9, pageName == name and 0.82 or 0.9, pageName == name and 0 or 0.9)
    end
    if pages[name] and pages[name].Refresh then pages[name]:Refresh() end
end

local function AddNavigation(name, order)
    local button = CreateFrame("Button", nil, SettingsWindow.sidebar, "BackdropTemplate")
    button:SetPoint("TOPLEFT", 10, -70 - (order - 1) * 42)
    button:SetPoint("TOPRIGHT", -10, -70 - (order - 1) * 42)
    button:SetHeight(36)
    button.highlight = button:CreateTexture(nil, "BACKGROUND")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(0.35, 0.28, 0.02, 0.62)
    button.label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    button.label:SetPoint("LEFT", 12, 0)
    button.label:SetText(name)
    button:SetScript("OnClick", function() ShowPage(name) end)
    navButtons[name] = button
end

local function CreateGeneralPage()
    local page = AddPage("General")
    local y = Section(page, "General", -14)
    Label(page, "Open this menu from the minimap launcher or with /las.", "GameFontHighlight", 28, y)
    y = y - 46
    page.minimap = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    page.minimap:SetPoint("TOPLEFT", 28, y)
    Label(page, "Show minimap button", "GameFontHighlight", 58, y - 4)
    page.minimap:SetScript("OnClick", function(self)
        NS.db.MinimapButton.hide = not self:GetChecked()
        NS:UpdateMinimapButton()
    end)
    y = Section(page, "Safe aura display", y - 42)
    Label(page, "Application counts are written directly by Blizzard to the text widget.", "GameFontHighlight", 28, y)
    Label(page, "The addon never reads or formats aura stack values in Lua.", "GameFontHighlight", 28, y - 28)
    function page:Refresh() self.minimap:SetChecked(NS.db.MinimapButton.hide ~= true) end
end

local function CreateTrackerPage()
    local page = AddPage("Trackers")
    page.inputs = {}
    local y = Section(page, "Aura trackers", -14)
    page.selected = Label(page, "", "GameFontNormal", 28, y)
    Button(page, "<", 350, y + 4, 26, function() selectedID = OrderedTrackerID(-1) page:Refresh() end)
    Button(page, ">", 382, y + 4, 26, function() selectedID = OrderedTrackerID(1) page:Refresh() end)
    Button(page, "New", 28, y - 36, 85, function()
        local tracker = NS:CreateTracker()
        selectedID = tracker.ID
        NS:RefreshTracker(selectedID)
        page:Refresh()
    end)
    Button(page, "Duplicate", 121, y - 36, 100, function()
        local tracker = NS:DuplicateTracker(selectedID)
        if tracker then
            selectedID = tracker.ID
            NS:RefreshTracker(selectedID)
            page:Refresh()
        end
    end)
    Button(page, "Delete", 229, y - 36, 85, function()
        NS:RemoveTrackerRuntime(selectedID)
        NS:DeleteTracker(selectedID)
        selectedID = NS:GetFirstTrackerID()
        page:Refresh()
    end)
    Button(page, "Preview", 322, y - 36, 85, function()
        local runtime = NS:EnsureTracker(selectedID)
        if runtime then NS:SetPreview(selectedID, not runtime.previewActive) end
    end)
    Button(page, "Unlock", 415, y - 36, 85, function() NS:ToggleUnlock(selectedID) end)
    y = Section(page, "Tracker settings", y - 86)
    local fields = { { "Name", "Name", 300 }, { "AuraIDs", "Aura IDs", 300 }, { "Unit", "Unit", 180 } }
    for _, field in ipairs(fields) do
        local input, key = Edit(page, field[2], field[1], 28, y, field[3])
        page.inputs[key] = input
        input:SetScript("OnEnterPressed", function(self) self:ClearFocus() ApplyTrackerInputs(page) end)
        y = y - 34
    end
    page.enabled = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    page.enabled:SetPoint("TOPLEFT", 28, y)
    Label(page, "Enabled", "GameFontHighlight", 58, y - 4)
    page.hideWhenMissing = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    page.hideWhenMissing:SetPoint("TOPLEFT", 205, y)
    Label(page, "Hide when missing", "GameFontHighlight", 235, y - 4)
    Button(page, "Apply tracker", 28, y - 42, 120, function() ApplyTrackerInputs(page) page:Refresh() end)
    function page:Refresh()
        local tracker = CurrentTracker()
        if not tracker then return end
        self.selected:SetText("Selected tracker: " .. (tracker.Name or tracker.ID))
        self.inputs.Name:SetText(tracker.Name or "")
        self.inputs.AuraIDs:SetText(NS:AuraIDsToText(tracker))
        self.inputs.Unit:SetText(tracker.Unit or "player")
        self.enabled:SetChecked(tracker.Enabled ~= false)
        self.hideWhenMissing:SetChecked(tracker.HideWhenMissing ~= false)
    end
end

local function CreatePositionPage()
    local page = AddPage("Positioning")
    page.inputs = {}
    local y = Section(page, "Layout & positioning", -14)
    Label(page, "CURSOR follows the mouse. FRAME anchors to a named UI frame. FIXED uses UIParent.", "GameFontHighlight", 28, y)
    y = y - 44
    page.mode = Dropdown(page, "Anchor mode", 28, y, 180, {
        { text = "Cursor", value = "CURSOR" }, { text = "Frame", value = "FRAME" }, { text = "Free position", value = "FIXED" },
    }, function()
        local tracker = CurrentTracker()
        return tracker and tracker.AnchorMode or "FIXED"
    end, function(value)
        local tracker = CurrentTracker()
        if tracker then
            tracker.AnchorMode = value
            NS:RefreshTracker(selectedID)
        end
    end)
    y = y - 48
    local input = Edit(page, "Anchor frame", "AnchorFrame", 28, y, 320)
    page.inputs.AnchorFrame = input
    input:SetScript("OnEnterPressed", function(self) self:ClearFocus() ApplyPositionInputs(page) end)
    y = y - 48
    local points = {
        { text = "Top left", value = "TOPLEFT" }, { text = "Top", value = "TOP" }, { text = "Top right", value = "TOPRIGHT" },
        { text = "Left", value = "LEFT" }, { text = "Center", value = "CENTER" }, { text = "Right", value = "RIGHT" },
        { text = "Bottom left", value = "BOTTOMLEFT" }, { text = "Bottom", value = "BOTTOM" }, { text = "Bottom right", value = "BOTTOMRIGHT" },
    }
    page.anchorPoint = Dropdown(page, "Your point", 28, y, 180, points, function()
        local tracker = CurrentTracker()
        return tracker and tracker.AnchorPoint or "CENTER"
    end, function(value)
        local tracker = CurrentTracker()
        if tracker then
            tracker.AnchorPoint = value
            NS:RefreshTracker(selectedID)
        end
    end)
    y = y - 48
    page.relativePoint = Dropdown(page, "Anchor point", 28, y, 180, points, function()
        local tracker = CurrentTracker()
        return tracker and tracker.RelativePoint or "CENTER"
    end, function(value)
        local tracker = CurrentTracker()
        if tracker then
            tracker.RelativePoint = value
            NS:RefreshTracker(selectedID)
        end
    end)
    y = y - 48
    page.offsetX = Slider(page, "Offset X", 28, y, 240, -600, 600, 1,
        function() local tracker = CurrentTracker() return tracker and tracker.OffsetX or 0 end,
        function(value) local tracker = CurrentTracker() if tracker then tracker.OffsetX = value end end)
    y = y - 48
    page.offsetY = Slider(page, "Offset Y", 28, y, 240, -400, 400, 1,
        function() local tracker = CurrentTracker() return tracker and tracker.OffsetY or 0 end,
        function(value) local tracker = CurrentTracker() if tracker then tracker.OffsetY = value end end)
    function page:Refresh()
        local tracker = CurrentTracker()
        if not tracker then return end
        self.mode:Refresh()
        self.inputs.AnchorFrame:SetText(tracker.AnchorFrame or "UIParent")
        self.anchorPoint:Refresh()
        self.relativePoint:Refresh()
        self.offsetX:Refresh()
        self.offsetY:Refresh()
    end
end

local function CreateAppearancePage()
    local page = AddPage("Appearance")
    local y = Section(page, "Text appearance", -14)
    Label(page, "Choose the size, outline, and colour of the stack number.", "GameFontHighlight", 28, y)
    y = y - 42
    page.size = Slider(page, "Text size", 28, y, 240, 12, 72, 1,
        function() local tracker = CurrentTracker() return tracker and tracker.FontSize or 28 end,
        function(value) local tracker = CurrentTracker() if tracker then tracker.FontSize = value end end)
    y = y - 48
    page.flags = Dropdown(page, "Outline", 28, y, 160, {
        { text = "None", value = "NONE" }, { text = "Outline", value = "OUTLINE" },
        { text = "Thick outline", value = "THICKOUTLINE" },
    }, function()
        local tracker = CurrentTracker()
        return tracker and tracker.FontFlags or "OUTLINE"
    end, function(value)
        local tracker = CurrentTracker()
        if tracker then
            tracker.FontFlags = value
            NS:RefreshTracker(selectedID)
        end
    end)
    y = y - 48
    page.textColour = ColourButton(page, "Text colour", 28, y,
        function() local tracker = CurrentTracker() return tracker and tracker.TextColor or { 1, 1, 1 } end,
        function(value) local tracker = CurrentTracker() if tracker then tracker.TextColor = value end end)
    y = Section(page, "Duration bar", y - 50)
    Label(page, "A compact bar below the number. Blizzard drives its duration directly.", "GameFontHighlight", 28, y)
    y = y - 42
    page.durationEnabled = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    page.durationEnabled:SetPoint("TOPLEFT", 28, y)
    Label(page, "Show duration bar", "GameFontHighlight", 58, y - 4)
    page.durationEnabled:SetScript("OnClick", function(self)
        local tracker = CurrentTracker()
        if tracker then
            tracker.ShowDurationBar = self:GetChecked() == true
            NS:RefreshTracker(selectedID)
        end
    end)
    y = y - 48
    page.durationWidth = Slider(page, "Bar width", 28, y, 240, 12, 120, 1,
        function() local tracker = CurrentTracker() return tracker and tracker.DurationBarWidth or 42 end,
        function(value) local tracker = CurrentTracker() if tracker then tracker.DurationBarWidth = value end end)
    y = y - 48
    page.durationHeight = Slider(page, "Bar height", 28, y, 240, 1, 8, 1,
        function() local tracker = CurrentTracker() return tracker and tracker.DurationBarHeight or 3 end,
        function(value) local tracker = CurrentTracker() if tracker then tracker.DurationBarHeight = value end end)
    y = y - 48
    page.durationColour = ColourButton(page, "Bar colour", 28, y,
        function() local tracker = CurrentTracker() return tracker and tracker.DurationBarColor or { 0.2, 0.8, 1 } end,
        function(value) local tracker = CurrentTracker() if tracker then tracker.DurationBarColor = value end end)
    function page:Refresh()
        local tracker = CurrentTracker()
        if not tracker then return end
        self.size:Refresh()
        self.flags:Refresh()
        self.textColour:Refresh()
        self.durationEnabled:SetChecked(tracker.ShowDurationBar == true)
        self.durationWidth:Refresh()
        self.durationHeight:Refresh()
        self.durationColour:Refresh()
    end
end

local function CreateSettingsWindow()
    local window = CreateFrame("Frame", "LafeeBDKBonesStacksSettings", UIParent, "BackdropTemplate")
    window:SetSize(920, 620)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    window:SetBackdropColor(0.035, 0.03, 0.045, 0.97)
    window:SetBackdropBorderColor(0.55, 0.45, 0.1, 0.9)
    window:Hide()
    window:SetScript("OnHide", function() NS:ClearAllPreviews() end)

    window.header = CreateFrame("Frame", nil, window, "BackdropTemplate")
    window.header:SetPoint("TOPLEFT", 5, -5)
    window.header:SetPoint("TOPRIGHT", -5, -5)
    window.header:SetHeight(54)
    window.header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    window.header:SetBackdropColor(0.01, 0.01, 0.015, 0.95)
    Label(window.header, NS.L.TITLE, "GameFontNormalLarge", 20, -17):SetTextColor(1, 0.82, 0)
    local close = CreateFrame("Button", nil, window.header, "UIPanelCloseButton")
    close:SetPoint("RIGHT", -5, 0)
    close:SetScript("OnClick", function() window:Hide() end)

    window.sidebar = CreateFrame("Frame", nil, window, "BackdropTemplate")
    window.sidebar:SetPoint("TOPLEFT", 5, -59)
    window.sidebar:SetPoint("BOTTOMLEFT", 5, 5)
    window.sidebar:SetWidth(190)
    window.sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    window.sidebar:SetBackdropColor(0.02, 0.02, 0.03, 0.78)
    Label(window.sidebar, "Settings", "GameFontNormal", 20, -25):SetTextColor(1, 0.82, 0)

    window.content = CreateFrame("Frame", nil, window)
    window.content:SetPoint("TOPLEFT", window.sidebar, "TOPRIGHT", 12, 0)
    window.content:SetPoint("BOTTOMRIGHT", -8, 8)
    SettingsWindow = window
    AddNavigation("General", 1)
    AddNavigation("Trackers", 2)
    AddNavigation("Positioning", 3)
    AddNavigation("Appearance", 4)
    CreateGeneralPage()
    CreateTrackerPage()
    CreatePositionPage()
    CreateAppearancePage()
end

function NS:InitializeSettings()
    if SettingsWindow then return end
    CreateSettingsWindow()
    if type(Settings) ~= "table" then return end
    local bridge = CreateFrame("Frame", nil, UIParent)
    Label(bridge, "Open the addon menu with the button below.", "GameFontHighlight", 20, -20)
    Button(bridge, "Open lafee bdk bones stacks", 20, -55, 220, function() NS:OpenSettings() end)
    local category = Settings.RegisterCanvasLayoutCategory(bridge, self.L.TITLE)
    Settings.RegisterAddOnCategory(category)
end

function NS:OpenSettings()
    if not SettingsWindow then self:InitializeSettings() end
    if not SettingsWindow then return end
    SettingsWindow:Show()
    ShowPage("Trackers")
    local tracker = CurrentTracker()
    if tracker then
        self:ClearAllPreviews()
        self:SetPreview(tracker.ID, true)
    end
end

function NS:ToggleSettings()
    if not SettingsWindow then self:InitializeSettings() end
    if not SettingsWindow then return end
    if SettingsWindow:IsShown() then SettingsWindow:Hide() else self:OpenSettings() end
end
