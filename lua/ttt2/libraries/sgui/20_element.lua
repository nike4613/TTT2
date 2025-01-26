---
-- The SGUI Element class
-- @class sgui.Element

local sgui = sgui

local CLS = sgui.Element or {}
CLS.Name = "Element"

---
-- Initialized the element.
-- @param table options The options table for the element.
function CLS:Init(options)
  self.options = options
end

---
-- Updates the options table for the element.
-- @param table options The options table for the element.
-- @return boolean Return true if the changes to the options table were handled; false if not. The element object will be re-created if it is not handled.
function CLS:Update(options)
  return false
end

function CLS:GetShadowTree()
  error(self.Name .. ":GetShadowTree() not implemented. Either implement that, or override :PerformLayout() and :RecordPaint().")
end

---
-- @param table parentSize The parent's sizing information
-- @param table children The children to layout
-- @return table Positioning table
-- { x, y, w, h } where they can be values based on pseudo-sizes and pseudo-positions. x/y, are relative to parent
function CLS:PerformLayout(parentSize, children)
  -- TODO: implement default functionality
end

---
-- Uses sgui.draw.* to virtually paint the element, such that it can be replayed during actual UI paint.
-- @param number w The virtual width of the element
-- @param number h The virtual height of the element
-- TODO: how do we handle scaling here? Is it passed in somehow? Do we do it all automatically? Is it handled only in final paint?
function CLS:RecordPaint(w, h)

end

CLS.mt = { __index = CLS }
sgui.Element = CLS
