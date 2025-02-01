---
-- The SGUI Element class
-- @class sgui.Element

local sgui = sgui
local sgui_local = sgui_local

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
-- Called before the core layout routines.
-- @note If you are deriving from Element and are not using @see{CLS:GetShadowTree}, override this to do nothing.
-- @param number The number of children this element was given.
function CLS:PrepareForLayout(childCount)
  self.cache = self.cache or sgui_local.Cache:new()
  self.childrenFillers = self.childrenFillers or {}
  local fillers = self.childrenFillers
  -- update the fillers list to have the right count
  while #fillers < childCount do
    fillers[#fillers + 1] = {
      type = sgui_local.NodeTy.Placeholder,
      idx = #fillers + 1,
    }
  end
  while #fillers > childCount do
    fillers[#fillers] = nil
  end

  self.root = self.cache:Update(self:GetShadowTree(), sgui_local.Params:new(self.options, fillers))
end

---
-- First pass of layout. This function is called on each element of the tree from the bottom up.
-- The implementation can ask for what size the children want to be and act on that. Child positions
-- should not be set until a later pass.
-- @note This should probably never be overridden. Good layout behavior depends on close coordination between
-- the sizing routines of every element in the tree.
-- @param table mgr The manager through which operations on children are performed.
-- @param table children The list of children for this element.
-- @return table A table describing the size this element wants to take up.
function CLS:GetChildDerivedSize(mgr, children)
  -- TODO:
end

---
-- Second pass of layout. This function is called on each element of the tree from the top down.
-- The implementation is given its parent's size, and is expected to determine a final absolure size.
-- @note This should probably never be overridden. Good layout behavior depends on close coordination between
-- the sizing routines of every element in the tree.
-- @param table mgr The manager through which information about the rest of the layout pass can be obtained.
-- @param table parentSize The final size of this element's parent.
-- @return table A table describing the final size of this element.
function CLS:GetParentDerivedSize(mgr, parentSize)
  -- TODO:
end

---
-- Final pass of layout. This function is called in an indeterminate order, and is expected ONLY to adjust the
-- positioning of children.
-- @note If special layout is required, this is the function to override.
-- @param table mgr The manager through which properties of the children can be obtained.
-- @param table size The final size of this element.
-- @param table children The list of children of this element.
function CLS:PerformLayout(mgr, size, children)
  -- TODO:
end

---
-- Uses sgui.draw.* to virtually paint the element, such that it can be replayed during actual UI paint.
-- @param number w The virtual width of the element
-- @param number h The virtual height of the element
-- TODO: how do we handle scaling here? Is it passed in somehow? Do we do it all automatically? Is it handled only in final paint?
function CLS:RecordPaint(w, h)

end

function CLS:RecordPaintAfter(w, h)

end

CLS.mt = { __index = CLS }
sgui.Element = CLS
