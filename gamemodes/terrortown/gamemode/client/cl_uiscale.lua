local dermaGetControlList = derma.GetControlList
local vguiGetControlTable = vgui.GetControlTable

local appearance = appearance

local currentIsHidpiAware = 0
local secretKey = {}
hidpi = hidpi or {}

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

    -- TODO: remove rescale matricies

    -- we've adjusted the width/height according to the scale
    return w, h
end

function hidpi.EndAware()
    -- TODO: restore rescale matricies

    -- exiting a hidpi-aware scope, decrement appropriately
    currentIsHidpiAware = currentIsHidpiAware - 1
    if currentIsHidpiAware < 0 then
        currentIsHidpiAware = 0
    end
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

                local scale = appearance.GetGlobalScale()
                w = w / scale
                h = h / scale

                -- TODO: rescale matricies here?
                local success, result = pcall(func, self, w, h)
                -- TODO: pop matrix?
                currentIsHidpiAware = cachedAware

                if not success then
                    error(result)
                end
                return result
            end
            continue -- the generic wrappers are built-in to the above
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
                -- TODO: insert rescale matricies, if necessary
                currentIsHidpiAware = 0
                local pck = table.Pack(pcall(func, ...))
                currentIsHidpiAware = cachedAware
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
    local success, result = pcall(dermaSkinHook, type, name, panel, ...)
    currentIsHidpiAware = cachedAware
    -- TODO: remove/insert rescale matricies if necessary
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
