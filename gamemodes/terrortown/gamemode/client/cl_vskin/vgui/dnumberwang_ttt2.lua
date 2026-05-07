local PANEL = {}

AccessorFunc(PANEL, "m_numMin", "Min")
AccessorFunc(PANEL, "m_numMax", "Max")
AccessorFunc(PANEL, "m_iDecimals", "Decimals") -- The number of decimal places in the output
AccessorFunc(PANEL, "m_fFloatValue", "FloatValue")
AccessorFunc(PANEL, "m_iInterval", "Interval")
AccessorFunc(PANEL, "m_tPermittedValues", "PermittedValues")

-- AnchorValue and UnAnchorValue functions are internally used for "drag-changing" the value
local function AnchorValue(wang, button, mcode)
    button:OldOnMousePressed(mcode)
    wang.mouseAnchor = gui.MouseY()
    wang.valAnchor = wang:GetValue()
end

local function UnAnchorValue(wang, button, mcode)
    button:OldOnMouseReleased(mcode)
    wang.mouseAnchor = nil
    wang.valAnchor = nil
end

---
-- @ignore
function PANEL:Init()
    -- Create the inner text entry directly rather than via self.BaseClass.Init(self).
    --
    -- DTextEntryTTT2:Init() ends with self:PerformLayout(), which dispatches to OUR
    -- override.  Our PerformLayout() references self.Up and self.Down, which don't
    -- exist yet at that point.  The resulting Lua error propagates back through
    -- BaseClass.Init and aborts our entire Init(), leaving m_iDecimals, m_numMin,
    -- m_numMax, the buttons, etc. all unset.  Any subsequent SetValue call then
    -- errors on the nil m_iDecimals (Format("%." .. nil .. "f", …)) and the
    -- _inSetValue guard gets permanently stuck at true, breaking everything.
    --
    -- Creating the TextArea inline – the same pattern used by DNumSliderTTT2 and
    -- DSearchBarTTT2 – avoids all of this.

    local textColor = util.GetActiveColor(
        util.GetChangedColor(util.GetDefaultColor(vskin.GetBackgroundColor()), 25)
    )

    self.TextArea = vgui.Create("DTextEntry", self)
    self.TextArea:SetFont("DermaTTT2Text")
    self.TextArea:SetTextColor(textColor)
    self.TextArea:SetCursorColor(textColor)

    -- Disable engine chrome; the TTT2 skin handles all rendering.
    self.TextArea:SetPaintBackgroundEnabled(false)
    self.TextArea:SetPaintBorderEnabled(false)
    self.TextArea:SetPaintBackground(false)

    self:SetPaintBackgroundEnabled(false)
    self:SetPaintBorderEnabled(false)
    self:SetPaintBackground(false)

    -- DTextEntryTTT2 accessor defaults.
    self:SetHeightMult(1)
    self:SetIsOnFocus(false)

    -- DPanelTTT2 tooltip state (normally set by DPanelTTT2:Init).
    self.tooltip = {
        fixedPosition = nil,
        fixedSize = nil,
        delay = 0,
        text = "",
        font = "DermaTTT2Text",
        sizeArrow = 8,
    }

    self:SetDecimals(2)
    self:SetTall(20)
    self:SetMinMax(0, 100)
    self:SetInterval(1)

    self:SetUpdateOnType(true)
    self.TextArea:SetNumeric(true)

    self.TextArea.OnGetFocus = function(_)
        self:SetIsOnFocus(true)
        self:OnGetFocus()
    end

    -- Route text-area changes through our SetValue so clamping/formatting/convars
    -- are applied.  SetValue has a re-entry guard to break any SetText → OnValueChange
    -- → SetValue cycle should one exist in the underlying DTextEntry.
    self.TextArea.OnValueChange = function(_, value)
        self:SetValue(value)
    end

    self.TextArea.OnLoseFocus = function(_)
        self:SetIsOnFocus(false)
        self:OnLoseFocus()
    end

    self.Up = vgui.Create("DButton", self)
    self.Up:SetText("")
    self.Up.DoClick = function()
        self:SetValue(self:GetNextValue(1))
    end
    self.Up.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "NumberUp", panel, w, h)
    end

    self.Up.OldOnMousePressed = self.Up.OnMousePressed
    self.Up.OldOnMouseReleased = self.Up.OnMouseReleased
    self.Up.OnMousePressed = function(button, mcode)
        AnchorValue(self, button, mcode)
    end
    self.Up.OnMouseReleased = function(button, mcode)
        UnAnchorValue(self, button, mcode)
    end

    self.Down = vgui.Create("DButton", self)
    self.Down:SetText("")
    self.Down.DoClick = function()
        self:SetValue(self:GetNextValue(-1))
    end
    self.Down.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "NumberDown", panel, w, h)
    end

    self.Down.OldOnMousePressed = self.Down.OnMousePressed
    self.Down.OldOnMouseReleased = self.Down.OnMouseReleased
    self.Down.OnMousePressed = function(button, mcode)
        AnchorValue(self, button, mcode)
    end
    self.Down.OnMouseReleased = function(button, mcode)
        UnAnchorValue(self, button, mcode)
    end

    self:SetValue(0)
end

---
-- @realm client
function PANEL:HideWang()
    self.Up:Hide()
    self.Down:Hide()
end

---
-- @ignore
function PANEL:OnMouseWheeled(delta)
    if delta ~= 0 then
        self:SetValue(self:GetNextValue(delta > 0 and 1 or -1))
    end

    return true
end

---
-- @ignore
function PANEL:Think()
    if self.mouseAnchor then
        self:SetValue(self.valAnchor + self.mouseAnchor - gui.MouseY())
    end
end

---
-- @param table tab
-- @realm client
function PANEL:SetPermittedValues(tab)
    if not tab then
        self.m_tPermittedValues = nil
        return
    end

    local copy = table.Copy(tab)
    table.sort(copy)
    self.m_tPermittedValues = copy
    self:SetValue(self:GetValue())
end

---
-- @param number dir
-- @return number
-- @realm client
function PANEL:GetNextValue(dir)
    if self.m_tPermittedValues then
        local current = self:GetValue()
        for i = 1, #self.m_tPermittedValues do
            if self.m_tPermittedValues[i] == current then
                local nextIdx = i + dir
                if nextIdx >= 1 and nextIdx <= #self.m_tPermittedValues then
                    return self.m_tPermittedValues[nextIdx]
                end
                break
            end
        end
        return dir > 0 and self.m_tPermittedValues[#self.m_tPermittedValues]
            or self.m_tPermittedValues[1]
    end
    return self:GetValue() + dir * self:GetInterval()
end

---
-- @param number num
-- @realm client
function PANEL:SetDecimals(num)
    self.m_iDecimals = num
    self:SetValue(self:GetValue())
end

---
-- @param number min
-- @param number max
-- @realm client
function PANEL:SetMinMax(min, max)
    self:SetMin(min)
    self:SetMax(max)
end

---
-- @param number min
-- @realm client
function PANEL:SetMin(min)
    self.m_numMin = tonumber(min)
end

---
-- @param number max
-- @realm client
function PANEL:SetMax(max)
    self.m_numMax = tonumber(max)
end

---
-- @return number
-- @realm client
function PANEL:GetFloatValue()
    if not self.m_fFloatValue then
        self.m_fFloatValue = 0
    end

    return tonumber(self.m_fFloatValue) or 0
end

---
-- @param number val
-- @param boolean ignoreConVar To avoid endless loops, separate setting of convars and UI values
-- @realm client
function PANEL:SetValue(val, ignoreConVar)
    -- Guard against re-entry: SetText triggers OnValueChange which calls SetValue again.
    if self._inSetValue then
        return
    end

    if val == nil then
        return
    end

    self._inSetValue = true

    val = tonumber(val) or 0

    if self.m_numMax ~= nil then
        val = math.min(self.m_numMax, val)
    end

    if self.m_numMin ~= nil then
        val = math.max(self.m_numMin, val)
    end

    if self.m_tPermittedValues then
        local closest = self.m_tPermittedValues[1]
        local minDiff = math.abs(val - closest)
        for i = 2, #self.m_tPermittedValues do
            local diff = math.abs(val - self.m_tPermittedValues[i])
            if diff < minDiff then
                minDiff = diff
                closest = self.m_tPermittedValues[i]
            end
        end
        val = closest
    end

    local valText
    if self.m_iDecimals == 0 then
        valText = Format("%i", val)
    elseif val ~= 0 then
        valText = Format("%." .. self.m_iDecimals .. "f", val)

        -- Trim trailing 0's and .'s – this gets rid of .00 etc
        valText = string.TrimRight(valText, "0")
        valText = string.TrimRight(valText, ".")
    else
        valText = tostring(val)
    end

    local hasChanged = tonumber(val) ~= tonumber(self:GetValue())

    -- Persist so GetValue() reflects the new value immediately.
    self.m_sValue = valText

    self.TextArea:SetText(valText)

    if hasChanged then
        if not ignoreConVar then
            self:SetConVarValues(valText)
        end

        self:OnValueChanged(val)
    end

    self._inSetValue = false
end

---
-- @return number
-- @realm client
function PANEL:GetValue()
    return tonumber(self.m_sValue) or 0
end

---
-- @param number value
-- @realm client
function PANEL:SetDefaultValue(value)
    local noDefault = true

    if isnumber(value) then
        self.default = value
        noDefault = false
    else
        self.default = nil
    end

    local reset = self:GetResetButton()

    if ispanel(reset) then
        reset.noDefault = noDefault
    end
end

---
-- @ignore
function PANEL:PerformLayout()
    local w, h = self:GetSize()
    local heightMult = self:GetHeightMult()

    -- Fill the panel with the text area (buttons float on top of the right edge,
    -- same as the base DNumberWang behaviour).
    self.TextArea:SetSize(w, h * heightMult)
    self.TextArea:SetPos(0, h * (1 - heightMult) * 0.5)
    self.TextArea:SetTextColor(
        util.GetActiveColor(
            util.GetChangedColor(util.GetDefaultColor(vskin.GetBackgroundColor()), 25)
        )
    )
    self.TextArea:InvalidateLayout(true)

    -- Position the increment/decrement buttons on the right side.
    local s = math.floor(h * 0.5)

    self.Up:SetSize(s, s - 1)
    self.Up:AlignRight(3)
    self.Up:AlignTop(0)

    self.Down:SetSize(s, s - 1)
    self.Down:AlignRight(3)
    self.Down:AlignBottom(2)
end

---
-- @realm client
function PANEL:SizeToContents()
    -- Size based on the max number and max amount of decimals.
    local chars = 0

    local min = math.Round(self:GetMin(), self:GetDecimals())
    local max = math.Round(self:GetMax(), self:GetDecimals())

    local minchars = string.len("" .. min .. "")
    local maxchars = string.len("" .. max .. "")

    chars = chars + math.max(minchars, maxchars)

    if self:GetDecimals() and self:GetDecimals() > 0 then
        chars = chars + 1
        chars = chars + self:GetDecimals()
    end

    self:InvalidateLayout(true)
    self:SetWide(chars * 6 + 10 + 5 + 5)
    self:InvalidateLayout()
end

---
-- @param number val
-- @return number
-- @realm client
function PANEL:GetFraction(val)
    local Value = val or self:GetValue()

    local Fraction = (Value - self.m_numMin) / (self.m_numMax - self.m_numMin)
    return Fraction
end

---
-- @param number val
-- @realm client
function PANEL:SetFraction(val)
    local Fraction = self.m_numMin + ((self.m_numMax - self.m_numMin) * val)
    self:SetValue(Fraction)
end

---
-- @param number val
-- @realm client
function PANEL:OnValueChanged(val) end

---
-- @return Panel
-- @realm client
function PANEL:GetTextArea()
    return self.TextArea
end

---
-- @ignore
function PANEL:GenerateExample(ClassName, PropertySheet, Width, Height)
    local ctrl = vgui.Create(ClassName)
    ctrl:SetDecimals(0)
    ctrl:SetMinMax(0, 255)
    ctrl:SetValue(3)

    PropertySheet:AddSheet(ClassName, ctrl, nil, true, true)
end

derma.DefineControl("DNumberWangTTT2", "Menu Option Line", PANEL, "DTextEntryTTT2")
