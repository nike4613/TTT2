---
-- A simple SGUI element class
--

local sgui = sgui

local CLS = {}
CLS.Name = "_SGUIElement"

function CLS:Init(options)
  sgui.Element.Init(self, options)
  self.shadowTree = table.FullCopy(self.defition)
  setmetatable(self.shadowTree, {__index=options})
end

function CLS:Update(options)
  setmetatable(self.shadowTree, {__index=options})
  return true
end

function CLS:GetShadowTree()
  return self.shadowTree
end

CLS.mt = { __index = CLS }
setmetatable(CLS, sgui.Element)

sgui.SGUIElement = sgui.SGUIElement or {}
sgui.SGUIElement.mt = CLS.mt
function sgui.SGUIElement.Define(definition)
  local cls = { definition = definition }
  setmetatable(cls, CLS.mt)
  return cls
end
