
local sgui = sgui

sgui.elements = sgui.elements or {}

---
-- Registers a purely declarative SGUI element.
-- @param string name The name of the element.
-- @param table tbl The SGUI element declaration.
-- @realm client
function sgui.Register(name, tbl)
  local cls = sgui.SGUIElement.Define(tbl)
  sgui.RegisterClass(name, cls)
end

---
-- Registers a dynamic SGUI element.
-- @param string name The name of the element.
-- @param table cs The SGUI element class definition.
-- @realm client
function sgui.RegisterClass(name, cls)
  -- set up the class correctly
  setmetatable(cls, sgui.Element.mt)
  cls.Name = name
  cls.mt = { __index = cls }

  sgui.elements[name] = cls
end

---
-- Gets an SGUI element by name.
-- @param string name The element name.
-- @return sgui.ELEMTYPE The ELEMTYPE of the element. This indicates how the following table must be interpreted.
-- @return table The SGUI element's table.
-- @realm client
function sgui.GetElement(name)
  return sgui.elements[name]
end
