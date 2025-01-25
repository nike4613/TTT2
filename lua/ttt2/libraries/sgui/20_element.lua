---
-- The SGUI Element class
-- @class sgui.Element

local sgui = sgui

local CLS = sgui.Element or {}
CLS.Name = "Element"

function CLS:Init(options)
  self.options = options
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
