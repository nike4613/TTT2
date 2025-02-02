---
-- Defines the VGUI panel which will ultimately contain the SGUI content.
-- @author DaNIke

local sgui = sgui
local sgui_local = sgui_local

local PANEL = {}

---
-- @ignore
function PANEL:Init()
  self._elemTbl = nil
  self._cache = sgui_local.Cache:new()
  self._paint = sgui_local.PaintContext:new()
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

---
-- @ignore
function PANEL:PerformLayout()
  self.tree = self._cache:Update(self:GetSGUIDef(), nil)

  local w, h = self:GetSize()
  self._cache:GetChildBasedSize(nil)
  local finalSize = self.tree.inst:GetParentBasedSize({w=w, h=h}, nil)
  self:SetSize(finalSize.w, finalSize.h)

  self._cache:PerformLayout()

  -- TODO: record paint
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
