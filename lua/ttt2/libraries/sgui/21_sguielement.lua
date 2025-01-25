---
-- A simple SGUI element class
--

local sgui = sgui

local CLS = {}
CLS.Name = "_SGUIElement"

-- TODO: implement properly
function CLS:Init(...)
  ErrorNoHaltWithStack("Bad call to _SGUIElement:Init(), which should never be called!")
  sgui.Element.Init(self, ...)
end

function CLS:PerformLayout(...)
  ErrorNoHaltWithStack("Bad call to _SGUIElement:PerformLayout(), which should never be called!")
  sgui.Element.PerformLayout(self, ...)
end

function CLS:RecordPaint(...)
  ErrorNoHaltWithStack("Bad call to _SGUIElement:RecordPaint(), which should never be called!")
  sgui.Element.RecordPaint(self, ...)
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
