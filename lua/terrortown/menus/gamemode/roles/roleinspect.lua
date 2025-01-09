--- @ignore

local table = table
local TryT = LANG.TryTranslation
local ParT = LANG.GetParamTranslation
local DynT = LANG.GetDynamicTranslation

CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"

CLGAMEMODESUBMENU.priority = 95
CLGAMEMODESUBMENU.title = "submenu_roles_roleinspect"

-- save the forms indexed by role index here to access from hook
CLGAMEMODESUBMENU.forms = {}

local function OptIndex(tbl, index)
    if tbl then
        return tbl[index]
    end
    return nil
end

local roleIconSize = 32

local function MakeRoleIcon(stage, roleIcons, role, decision, paramFmt)
    local roleData = roles.GetByIndex(role)

    local ic = roleIcons:Add("DRoleImageTTT2")
    ic:SetSize(roleIconSize, roleIconSize)
    ic:SetMaterial(roleData.iconMaterial)
    ic:SetColor(roleData.color)
    ic:SetEnabled(decision.decision == ROLEINSPECT_DECISION_CONSIDER)
    ic:SetMouseInputEnabled(true)

    local stageShortName = roleinspect.GetStageName(stage)

    local params = {
        name = roleData.name,
        decision = roleinspect.GetDecisionFullName(decision.decision),
        reason = decision.reason
            .. "_d_" .. roleinspect.GetDecisionName(decision.decision)
            ..  "_s_" .. stageShortName,
    }

    if paramFmt then
        params = paramFmt(params) or params
    end

    ic:SetTooltip(DynT(
        "tooltip_" .. stageShortName .. "_role_desc",
        params,
        true
    ))
    ic:SetTooltipFixedPosition(0, roleIconSize)

    ic.subrole = role

    return ic
end

local function PopulatePreselectRoleStage(stage, form, stageData)
    local stageFullName = roleinspect.GetStageFullName(stage)

    form:MakeHelp({
        label = "help_" .. stageFullName,
        params = {
            maxPlayers = stageData.extra.maxPlayers[1]
        }
    })

    local finalRoleCounts = stageData.extra.finalRoleCounts[1]

    -- generate an icon layout containing all of the roles processed
    local roleIcons = form:MakeIconLayout()

    for role, roleInspectData in pairs(stageData.roles) do
        local decision = roleInspectData.decisions[1]
        MakeRoleIcon(stage, roleIcons, role, decision, function(params)
            params.finalCount = tostring(finalRoleCounts[role] or 0)
        end)
    end
end

local function PopulateLayeringRoleStage(stage, form, stageData)
    local stageFullName = roleinspect.GetStageFullName(stage)

    form:MakeHelp({
        label = "help_" .. stageFullName,
        params = {
            maxRoles = OptIndex(stageData.extra.maxRoles, 1) or "N/A",
            maxBaseroles = OptIndex(stageData.extra.maxBaseroles, 1) or "N/A",
        }
    })

    -- we want to create a setup similar to the normal role layering UI to present this
    local finalSelectableRoles = stageData.extra.finalSelectableRoles[1]

    local function ComputeActualUnlayered(rawAvailable, layers, unlayeredInitial)
        local unlayered = unlayeredInitial or {}
        -- actually build the base unlayered list
        for _,role in pairs(rawAvailable) do
            unlayered[#unlayered + 1] = role
        end

        if layers then
            -- then go through the layers to remove from the unlayered list ones which are layered
            local k = 1
            while k <= #layers do
                local layer = layers[k]
                local i = 1
                while i <= #layer do
                    local role = layer[i]
                    local idx
                    for j = 1,#unlayered do
                        if role == unlayered[j] then
                            idx = j
                            break
                        end
                    end

                    if idx then
                        table.remove(unlayered, idx)
                        i = i + 1
                    else
                        -- the role wasn't in the raw set of available roles, so
                        -- isn't a candidate and shouldn't be shown in the layers ui
                        table.remove(layer, i)
                    end
                end

                -- make sure to remove newly-empty layers
                if #layer == 0 then
                    table.remove(layers, k)
                else
                    k = k + 1
                end
            end
        end

        return unlayered
    end

    local function ProcessLayer(icons, layer)
        for _,role in pairs(layer) do
            local decision
            local roleData = stageData.roles[role]
            if not roleData and (role == ROLE_INNOCENT or role == ROLE_TRAITOR) then
                decision = {
                    decision = ROLEINSPECT_DECISION_CONSIDER,
                    reason = ROLEINSPECT_REASON_FORCED,
                }
            else
                decision = roleData and roleData.decisions[1] or {
                    decision = ROLEINSPECT_DECISION_NO_CONSIDER,
                    reason = ROLEINSPECT_REASON_NOT_LAYERED
                }
            end
            MakeRoleIcon(stage, icons, role, decision, function(params)
                params.finalCount = tostring(finalSelectableRoles[role] or 0)
            end)
        end
    end

    local function PresentLayers(parent, layers, unlayered)
        local layout = parent:MakeIconLayout()

        if layers then
            -- first, layers
            local layersIcons = layout:Add("DRoleLayeringReceiverTTT2")
            layersIcons:SetLeftMargin(108)
            layersIcons:Dock(TOP)
            layersIcons:SetPadding(5)
            layersIcons:SetLayers(layers)
            layersIcons:SetChildSize(roleIconSize, roleIconSize)

            for _,layer in pairs(layers) do
                ProcessLayer(layersIcons, layer)
            end
        end

        if #unlayered > 0 then
            -- then unlayered
            local unlayeredIcons = layout:Add("DRoleLayeringSenderTTT2")
            unlayeredIcons:SetLeftMargin(108)
            unlayeredIcons:Dock(TOP)
            unlayeredIcons:SetPadding(5)
            unlayeredIcons:SetChildSize(roleIconSize, roleIconSize)

            ProcessLayer(unlayeredIcons, unlayered)
        end
    end

    -- to that end, we want to compute the layered/unlayered baseroles
    local baseroleLayers = stageData.extra.afterBaseRoleLayers[1]
    local unlayeredBaseroles = ComputeActualUnlayered(
        stageData.extra.afterAvailableBaseRoles[1],
        baseroleLayers,
        { ROLE_INNOCENT, ROLE_TRAITOR }
    )

    local baseroleLayersForm = vgui.CreateTTT2Form(form, "header_inspect_layers_baseroles")

    -- now create the icons for each of the layers
    PresentLayers(baseroleLayersForm, baseroleLayers, unlayeredBaseroles)

    -- present subroleSelectBaseroleOrder
    local subroleSelectBaseroleOrder = stageData.extra.subroleSelectBaseroleOrder
    local orderForm = vgui.CreateTTT2Form(form, "header_inspect_layers_order")
    orderForm:MakeHelp({
        label = "help_inspect_layers_order",
    })
    orderForm = orderForm:MakeIconLayout()
    orderForm:SetBorder(5)
    orderForm:SetSpaceX(5)
    orderForm:SetSpaceY(5)
    orderForm:SetStretchHeight(true)

    for i = 1,#subroleSelectBaseroleOrder do
        local orderItem = subroleSelectBaseroleOrder[i]
        local baseroleData = roles.GetByIndex(orderItem.baserole)
        local subroleData = roles.GetByIndex(orderItem.subrole)

        local entry = vgui.Create("DPiPPanelTTT2", orderForm)
        entry:SetPadding(4)
        entry:SetOuterOffset(4)

        -- first added panel is the main one
        local ic = entry:Add("DRoleImageTTT2")
        ic:SetSize(roleIconSize, roleIconSize)
        ic:SetMaterial(baseroleData.iconMaterial)
        ic:SetColor(baseroleData.color)
        ic:SetMouseInputEnabled(true)
        ic:SetTooltip(DynT(
            "tooltip_inspect_layers_baserole",
            { name = baseroleData.name },
            true
        ))
        ic:SetTooltipFixedPosition(0, roleIconSize)

        -- align bottom-right, preferred-axis X
        ic = entry:Add("DRoleImageTTT2", RIGHT, BOTTOM)
        ic:SetSize(roleIconSize * 2 / 3, roleIconSize * 2 / 3)
        ic:SetMaterial(subroleData.iconMaterial)
        ic:SetColor(subroleData.color)
        ic:SetMouseInputEnabled(true)
        ic:SetTooltip(DynT(
            "tooltip_inspect_layers_subrole",
            { name = subroleData.name },
            true
        ))
        ic:SetTooltipFixedPosition(0, roleIconSize * 2 / 3)
    end

    local availableSubroles = stageData.extra.afterAvailableSubRoles[1]
    local subroleLayers = stageData.extra.afterSubRoleLayers[1]

    -- generate the same thing for the subroles of each baserole
    for baserole,subroles in pairs(availableSubroles) do
        local layers = subroleLayers[baserole]
        local unlayeredSubroles = ComputeActualUnlayered(subroles, layers)
        local baseroleData = roles.GetByIndex(baserole)

        local layersForm = vgui.CreateTTT2Form(form, DynT(
            "header_inspect_layers_subroles",
            { baserole = baseroleData.name },
            true
        ))

        PresentLayers(layersForm, layers, unlayeredSubroles)
    end

    -- TODO: display subroleSelectBaseroleOrder in a reasonable way

end

local function PopulateBaserolesStage(stage, form, stageData)
    local stageFullName = roleinspect.GetStageFullName(stage)

    form:MakeHelp({
        label = "help_" .. stageFullName,
        params = {

        }
    })

    -- go through the assignment order to display selection info
    for i,assignment in pairs(stageData.extra.assignOrder) do
        -- assignment has amount, players, role
        local role = assignment.role
        local roleData = roles.GetByIndex(role)

        local itemForm = vgui.CreateTTT2Form(form, DynT(
            "header_inspect_baseroles_order",
            { name = roleData.name },
            true
        ))

        local playerGraph = vgui.Create("DPlayerGraphTTT2", itemForm)
        playerGraph:Dock(TOP)

        local recordedRoleData = stageData.roles[role]
        local decisions = recordedRoleData.decisions
        local playerWeights = recordedRoleData.extra.playerWeights[1]

        for k = 1,#assignment.players do
            local ply = assignment.players[k]

            local isHighlight = false
            for j = 1,#decisions do
                local dec = decisions[j]
                if dec.ply == ply then
                    isHighlight = true
                    break
                end
            end

            playerGraph:AddPlayer(ply, playerWeights[ply], isHighlight)
        end

    end

end

local function PopulateSubrolesStage(stage, form, stageData)
    local stageFullName = roleinspect.GetStageFullName(stage)

    form:MakeHelp({
        label = "help_" .. stageFullName,
        params = {

        }
    })

    -- TODO:
end

local function PopulateFinalStage(stage, form, stageData)
    local stageFullName = roleinspect.GetStageFullName(stage)

    form:MakeHelp({
        label = "help_" .. stageFullName,
        params = {

        }
    })

    -- TODO:
end

local populateStageTbl = {
    [ROLEINSPECT_STAGE_PRESELECT] = PopulatePreselectRoleStage,
    [ROLEINSPECT_STAGE_LAYERING] = PopulateLayeringRoleStage,
    [ROLEINSPECT_STAGE_BASEROLES] = PopulateBaserolesStage,
    [ROLEINSPECT_STAGE_SUBROLES] = PopulateSubrolesStage,
    [ROLEINSPECT_STAGE_FINAL] = PopulateFinalStage
}

local function PopulateUnhandledRoleStage(stage, form, stageData)
    form:MakeHelp({
        label = "help_" .. roleinspect.GetStageFullName(stage),
    })

    -- TODO: read decisions to try to create a crude approximation of the data in
    -- the case of new stages
end

function CLGAMEMODESUBMENU:Populate(parent)
    -- first add a tutorial form
    local form = vgui.CreateTTT2Form(parent, "header_roleinspect_info")

    form:MakeHelp({
        label = "help_roleinspect",
    })

    form:MakeCheckBox({
        serverConvar = "ttt2_roleinspect_enable",
        label = "label_roleinspect_enable",
    })

    self.hasData = false

    roleinspect.GetDecisions(function(roleinspectTable)
        if self.hasData then return end

        -- the provided table is the decisions table, or an empty table if the data is not available
        if #roleinspectTable == 0 then
            -- empty table, put in an appropriate message

            local labelNoContent = vgui.Create("DLabelTTT2", parent)
            labelNoContent:SetText("label_menu_not_populated")
            labelNoContent:SetFont("DermaTTT2Title")
            labelNoContent:SetPos(20, 200)
            --labelNoContent:FitContents()
            return
        end

        self.hasData = true

        -- we've recieved data, set up UI
        for stage, stageData in pairs(roleinspectTable) do
            local stageFullName = roleinspect.GetStageFullName(stage)
            local stageForm = vgui.CreateTTT2Form(parent, "header_" .. stageFullName)

            local populateFn = populateStageTbl[stage] or PopulateUnhandledRoleStage
            populateFn(stage, stageForm, stageData)
        end

    end)
end

function CLGAMEMODESUBMENU:PopulateButtonPanel(parent)
    --[[
    local buttonReset = vgui.Create("DButtonTTT2", parent)

    buttonReset:SetText("button_reset")
    buttonReset:SetSize(100, 45)
    buttonReset:SetPos(20, 20)
    buttonReset.DoClick = function()
        rolelayering.SendDataToServer(ROLE_NONE, {})

        for subrole in pairs(self.subroleList) do
            rolelayering.SendDataToServer(subrole, {})
        end
    end
    ]]
end

function CLGAMEMODESUBMENU:HasButtonPanel()
    --return true
    return false
end