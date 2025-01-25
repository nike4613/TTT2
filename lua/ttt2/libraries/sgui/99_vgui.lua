---
-- Defines the VGUI panel which will ultimately contain the SGUI content.
-- @author DaNIke

local sgui = sgui

local PANEL = {}

---
-- @ignore
function PANEL:Init()
  self._elemTbl = nil
  self._elemTreeCache = nil
  self._vguiCache = {}
  self._renderList = nil
end

---
-- @return table The element definition table.
-- @realm client
function PANEL:GetSGUIDef()
  return isfunction(self._elemTbl) and self._elemTbl() or self._elemTbl
end

---
-- Sets the SGUI definition associated with this VGUI element.
-- @param table|function tbl The SGUI definition table, or a function returning the SGUI definition table.
function PANEL:SetSGUI(tbl)
  self._elemTbl = tbl
  self:InvalidateLayout()
end


-- @return table
local function VisitSGUIDef(pnl, reusedPaths, path, tree, oldTree, parentSizing)

end

---
-- @ignore
function PANEL:PerformLayout()
  -- recall the previous tree
  local oldTree = self._elemTreeCache

  -- clear the various lists
  self._elemTreeCache = nil
  local reusedPaths = {}

  -- get the new tree
  local newTree = self:GetSGUIDef()

  -- perform layout (TODO: get size and position out of this and assign it)
  VisitSGUIDef(self, reusedPaths, ".", newTree, oldTree)

  -- save the tree for the next layout
  self._elemTreeCache = table.FullCopy(newTree)

  -- clear out the unused VGUI elements from the VGUI cache
  -- TODO:
end

---
-- @ignore
function PANEL:Paint(w, h)

  return true
end

---
-- @ignore
function PANEL:PaintOver(w, h)

  return true
end


sgui.vguiBridge = vgui.RegisterTable(PANEL)
