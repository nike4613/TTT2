TOP = "ALIGN_TOP"
CENTER = "ALIGN_CENTER"

local fmt = {
    ty = "box",
    margin = 5,
    fill = true,
    {
        ty = "box",
        align = TOP,
        height = 20,
        fill = true,
        {
            ty = "text",
            translate = true,
            text = "some_text_key",
            align = { CENTER, CENTER },
        },
    },
    {
        vgui = "DPiPPanelTTT2",
        set = { Player = LocalPlayer() },
        init = function(pnl) end,
    },
}

function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = "\"" .. k .. "\""
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

print(dump(fmt))
