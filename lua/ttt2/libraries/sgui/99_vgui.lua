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
  local prevAmbient = self._cache:SetAmbient()

  local w, h = self:GetSize()
  local finalSize = self.tree.inst:PerformLayout({w=w, h=h}, self.tree.children)
  self:SetSize(finalSize.w, finalSize.h)
  self:SetPos(finalSize.x, finalSize.y)

  sgui_local.Cache.SetAmbient(prevAmbient)
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
