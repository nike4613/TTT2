local appearance = appearance

local currentIsHidpiAware = 0
local currentHasScaleMatrix = false
local noHidpiShouldGetMatrix = false

hidpi = hidpi or {}

local function MaybePushScaleMatrixForCurAware(scale)
    if currentIsHidpiAware == 0 and noHidpiShouldGetMatrix and not currentHasScaleMatrix then
        if not scale then scale = appearance.GetGlobalScale() end
        local mat = Matrix()
        mat:Scale(Vector(scale, scale))
        cam.PushModelMatrix(mat, true)
        currentHasScaleMatrix = true
    end
end

local function MaybePopScaleMatrixForCurAware()
    if currentIsHidpiAware ~= 0 and currentHasScaleMatrix then
        cam.PopModelMatrix()
        currentHasScaleMatrix = false
    end
end

function hidpi.Aware(w, h)
    if currentIsHidpiAware > 0 then
        -- if we're already in a hidpi, we don't need to scale the passed size, and don't need to do anything at all
        return w, h
    end

    if isnumber(w) or isnumber(h) then
        -- we're not in a hidpi-aware context, the width/height are lying, we need to rescale
        local scale = appearance.GetGlobalScale()
        if isnumber(w) then
            w = w * scale
        end
        if isnumber(h) then
            h = h * scale
        end
    end

    -- entering a hidpi-aware scope, increment our counter
    currentIsHidpiAware = currentIsHidpiAware + 1
    MaybePopScaleMatrixForCurAware()

    -- we've adjusted the width/height according to the scale
    return w, h
end

function hidpi.EndAware()
    -- exiting a hidpi-aware scope, decrement appropriately
    currentIsHidpiAware = currentIsHidpiAware - 1
    if currentIsHidpiAware < 0 then
        currentIsHidpiAware = 0
    end

    MaybePushScaleMatrixForCurAware()
end

function hidpi.IsAware()
    return currentIsHidpiAware > 0
end

function hidpi.RescaleFromAware(x, y, w, h)
    local scale = appearance.GetGlobalScale()
    if isnumber(x) then x = x / scale end
    if isnumber(y) then y = y / scale end
    if isnumber(w) then w = w / scale end
    if isnumber(h) then h = h / scale end
    return x, y, w, h
end

function hidpi.RescaleToAware(x, y, w, h)
    local scale = appearance.GetGlobalScale()
    if isnumber(x) then x = x * scale end
    if isnumber(y) then y = y * scale end
    if isnumber(w) then w = w * scale end
    if isnumber(h) then h = h * scale end
    return x, y, w, h
end

local function FixPanelForScaling(pnl, isDerma)
    -- we need to fix up the panel for hidpi-awareness.
    -- This basically means wrapping EVERY SINGLE FUNCTION in a wrapper that adjusts the hidpi mode,
    -- with several well-known functions manually being overridden.

    -- first, look for the hidpi marker
    local hasHidpiMarker = isfunction(pnl["TTT2PanelIsHidpiAware"])
    local hasNoAwareWrapper = isfunction(pnl["TTT2BlockHidpiAwareWrappers"])

    for name, func in pairs(pnl) do
        -- first, handle special functions
        if not hasHidpiMarker and (name == "Paint" or name == "PaintOver") then
            -- A paint function. We need to push a scale matrix, and rescale incoming parameters (but only if not hidpi-aware)
            pnl[name] = function(self, w, h)
                local cachedAware = currentIsHidpiAware
                currentIsHidpiAware = 0

                -- strictly speaking, when Paint is called, we're always supposed to be hidpi-aware
                local scale = appearance.GetGlobalScale()
                if isnumber(w) then w = w / scale end
                if isnumber(h) then h = h / scale end

                local cachedShouldGetMatrix = noHidpiShouldGetMatrix
                noHidpiShouldGetMatrix = true
                MaybePushScaleMatrixForCurAware(scale)

                local success, result = pcall(func, self, w, h)

                noHidpiShouldGetMatrix = cachedShouldGetMatrix
                currentIsHidpiAware = cachedAware
                MaybePopScaleMatrixForCurAware()

                if not success then
                    error(result)
                end
                return result
            end
            continue -- the generic wrappers are built-in to the above
        -- TODO: some of these might be overridden by panels, and so should be replaced below. What reasonable scheme can we use for that?
        elseif
            name == "GetLineHeight"
            or name == "GetX"
            or name == "GetY"
            or name == "GetTall"
            or name == "GetWide"
            or name == "Distance"
        then
            -- 1x rescaled return
            pnl[name] = function(self, ...)
                local x = func(self, ...)

                if not hidpi.IsAware() then
                    x = hidpi.RescaleFromAware(x)
                end

                return x
            end
            continue
        elseif
            name == "GetPos"
            or name == "GetSize"
            or name == "GetChildPosition"
            or name == "GetContentSize"
            or name == "GetTextInset"
            or name == "GetTextSize"
            or name == "LocalCursorPos"
            or name == "ChildrenSize"
            or name == "CursorPos"
        then
            -- 2x rescaled return
            pnl[name] = function(self, ...)
                local x, y = func(self, ...)

                if not hidpi.IsAware() then
                    -- caller is not hidpi aware, need to rescale
                    x, y = hidpi.RescaleFromAware(x, y)
                end

                return x, y
            end
            continue
        elseif
            name == "GetBounds"
            or name == "GetDockMargin"
            or name == "GetDockPadding"
        then
            -- 4x rescaled return
            pnl[name] = function(self, ...)
                local x, y, w, h = func(self, ...)

                if not hidpi.IsAware() then
                    x, y, w, h = hidpi.RescaleFromAware(x, y, w, h)
                end

                return x, y, w, h
            end
            continue
        elseif
            name == "LocalToScreen"
            or name == "ScreenToLocal"
        then
            pnl[name] = function(self, x, y)
                local scale
                -- first, we rescale into hidpi-aware space
                if not hidpi.IsAware() then
                    scale = appearance.GetGlobalScale()
                    x = x * scale
                    y = y * scale
                end

                -- then, call the underlying function
                x, y = func(self, x, y)

                -- then, rescale back into non-hidpi-aware space
                if not hidpi.IsAware() then
                    x = x / scale
                    y = y / scale
                end

                return x, y
            end
            continue
        elseif
            name == "DistanceFrom"
        then
            pnl[name] = function(self, x, y)
                local scale
                -- first, we rescale into hidpi-aware space
                if not hidpi.IsAware() then
                    scale = appearance.GetGlobalScale()
                    x = x * scale
                    y = y * scale
                end

                -- then, call the underlying function
                x = func(self, x, y)

                -- then, rescale back into non-hidpi-aware space
                if not hidpi.IsAware() then
                    x = x / scale
                end

                return x
            end
            continue
        elseif
            name == "MoveAbove"
            or name == "MoveBelow"
            or name == "MoveLeftOf"
            or name == "MoveRightOf"
            or name == "SetPlayer"
            or name == "SetSteamID"
            or name == "StretchBottomTo"
            or name == "StretchRightTo"
        then
            -- second parameter 1x scaled offset
            pnl[name] = function(self, panel, offset, ...)
                if not hidpi.IsAware() then
                    offset = hidpi.RescaleToAware(offset)
                end

                return func(self, panel, offset, ...)
            end
            continue
        elseif
            name == "SetHeight"
            or name == "SetTall"
            or name == "SetWidth"
            or name == "SetWide"
            or name == "SetX"
            or name == "SetY"
            or name == "SizeToContentsX"
            or name == "SizeToContentsY"
            or name == "AlignBottom"
            or name == "AlignLeft"
            or name == "AlignRight"
            or name == "AlignTop"
        then
            -- 1x rescaled first parameter
            pnl[name] = function(self, x, ...)
                if not hidpi.IsAware() then
                    x = hidpi.RescaleToAware(x)
                end

                return func(self, x, ...)
            end
            continue
        elseif
            name == "MoveBy"
            or name == "MoveTo"
            or name == "PaintAt"
            or name == "SetMinimuimSize"
            or name == "SetPos"
            or name == "SetSize"
            or name == "SetTextInset"
            or name == "SizeTo"
        then
            -- 2x rescaled first parameters
            pnl[name] = function(self, x, y, ...)
                if not hidpi.IsAware() then
                    x, y = hidpi.RescaleToAware(x, y)
                end

                return func(self, x, y, ...)
            end
            continue
        elseif
            name == "SetDropTarget"
            or name == "StretchToParent"
            or name == "DockMargin"
            or name == "DockPadding"
        then
            -- 4x rescaled first parameters
            pnl[name] = function(self, x, y, z, w, ...)
                if not hidpi.IsAware() then
                    x, y, z, w = hidpi.RescaleToAware(x, y, z, w)
                end

                return func(self, x, y, z, w, ...)
            end
            continue
        elseif
            name == "PositionLabel"
        then
            -- 3x rescaled first parameters + 1x rescaled return
            pnl[name] = function(self, x, y, z, ...)
                if not hidpi.IsAware() then
                    x, y, z = hidpi.RescaleToAware(x, y, z)
                end

                local w = func(self, x, y, z, ...)

                if not hidpi.IsAware() then
                    w = hidpi.RescaleFromAware(w)
                end

                return w
            end
            continue
        end
        -- TODO:

        -- otherwise, use our generic wrappers
        if hasHidpiMarker then
            if not hasNoAwareWrapper then
                -- use the wrapper that switches us into hidpi-aware mode
                pnl[name] = function(...)
                    hidpi.Aware()
                    local pck = table.Pack(pcall(func, ...))
                    hidpi.EndAware()
                    if not pck[1] then
                        error(pck[2])
                    end
                    return unpack(pck, 2)
                end
            end
        else
            -- use the wrapper that makes sure we're NOT in hidpi-aware mode
            pnl[name] = function(...)
                local cachedAware = currentIsHidpiAware
                currentIsHidpiAware = 0
                MaybePushScaleMatrixForCurAware()
                local pck = table.Pack(pcall(func, ...))
                currentIsHidpiAware = cachedAware
                MaybePopScaleMatrixForCurAware()
                if not pck[1] then
                    error(pck[2])
                end
                return unpack(pck, 2)
            end
        end
    end
end

-- override derma.SkinHook so we can properly track hidpi-awareness
local dermaSkinHook = derma.SkinHook
function derma.SkinHook(type, name, panel, ...)
    -- save and restore hidpi scope on entry to be tolerant of mismatched Aware()/EndAware() calls
    -- but also make sure we don't accidentially leave it on in case of an error
    local cachedAware = currentIsHidpiAware

    local panelSkin = panel:GetSkin()
    if panelSkin then
        if isfunction(panelSkin["TTT2SkinIsHidpiAware"]) then
            -- the skin is aware, wrap the call with it
            hidpi.Aware()
        else
            -- the skin is NOT aware, make sure we're in a non-aware context
            currentIsHidpiAware = 0
            MaybePushScaleMatrixForCurAware()
        end
    end

    local success, result = pcall(dermaSkinHook, type, name, panel, ...)

    currentIsHidpiAware = cachedAware
    MaybePopScaleMatrixForCurAware()

    if not success then
        error(result)
    end
    return result
end

-- override derma.DefineControl so we can fix up future panels as they're defined
local dermaDefineControl = derma.DefineControl
function derma.DefineControl(name, desc, pnl, base, ...)
    local result = dermaDefineControl(name, desc, pnl, base, ...)
    FixPanelForScaling(result, true)
    return result
end

-- override vgui.Register to do the same kind of fixup
local vguiRegister = vgui.Register
function vgui.Register(name, pnl, base, ...)
    local result = vguiRegister(name, pnl, base, ...)
    FixPanelForScaling(result, false)
    return result
end

-- similar for RegisterFile and RegisterTable
local vguiRegisterFile = vgui.RegisterFile
function vgui.RegisterFile(file, ...)
    local result = vguiRegisterFile(file, ...)
    FixPanelForScaling(result, false)
    return result
end

local vguiRegisterTable = vgui.RegisterTable
function vgui.RegisterTable(pnl, base, ...)
    local result = vguiRegisterTable(pnl, base, ...)
    FixPanelForScaling(result, false)
    return result
end

-- now that the derma hooks are installed, lets go through (some of the) existing registrations to fix them up
local function FixupExistingRegistrations()
    local visited = {}
    local pending = {
        -- Manual panels to patch
        "Panel",
        "DPanel",
        "DFrame",
        "DLabel",
        "DLabelEditable",
        "DTextEntry",
        "DButton",
        "DExpandButton",
        "DBinder",
        "DCheckBox",
        "DCheckBoxLabel",
        "ImageCheckBox",
        "DComboBox",
        "DImage",
        "DImageButton",
        "DCategoryList",
        "DCollapsibleCategory",
        "DForm",
        "DSlider",
        "DNumSlider",
        "DNumberWang",
        "DPropertySheet",
        "DMenu",
        "DProgress",
        "DHTML",
        "DHTMLControls",
        "DColorButton",
        "DColorPalette",
        "DColorCombo",
        "DColorCube",
        "DColorMixer",
        "DRGBPicker",
        "DAlphaBar",
        "DDragBase",
        "DSizeToContents",
        "DIconLayout",
        "DListLayout",
        "DGrid",
        "DHorizontalScroller",
        "DTooltip",
        "DDrawer",
        "DListView",
        "Frame",
        "HTML",
    }

    -- Now go through Derma panels and add them all to pending
    local dermaControls = derma.GetControlList()
    for i = 1, #dermaControls do
        pending[#pending + 1] = dermaControls[i].ClassName
    end

    -- Then actually go through the panels and patch them
    while #pending > 0 do
        local panelName = pending[1]
        table.remove(pending, 1)
        if visited[panelName] then continue end
        visited[panelName] = true

        local panelTable = vgui.GetControlTable(panelName)
        -- queue the base as appropriate
        if not visited[panelTable.Base] then
            pending[#pending + 1] = panelTable.Base
        end

        -- patch the panel
        FixPanelForScaling(panelTable)
    end

end

FixupExistingRegistrations()