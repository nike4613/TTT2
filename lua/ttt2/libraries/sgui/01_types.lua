local sgui = sgui
local sgui_local = sgui_local

---
-- @class UnitSize
local UnitSize = {}

---
-- @enum UnitSize.Unit
UnitSize.Unit = {
  Pt = 0,
  Em = 1,
  Percent = 2,
}


UnitSize.UnitNames = {
  [UnitSize.Unit.Pt] = "pt",
  [UnitSize.Unit.Em] = "em",
  [UnitSize.Unit.Percent] = "%",
}

UnitSize.UnitAliases = {
  ["pt"] = UnitSize.Unit.Pt,
  ["px"] = UnitSize.Unit.Pt,
  [""] = UnitSize.Unit.Pt,
  ["em"] = UnitSize.Unit.Em,
  ["pct"] = UnitSize.Unit.Percent,
  ["%"] = UnitSize.Unit.Percent,
}

UnitSize._mt = {
  __index = UnitSize,
  __tostring = function(self)
    return "UnitSize(" .. self.value .. UnitSize.UnitNames[self.unit] .. ")"
  end,

}

function UnitSize:new(value, unit)
  unit = unit or self.Unit.Pt
  if not isnumber(value) then
    error("value must be a number, not " .. type(value))
  end
  if not self.UnitNames[unit] then
    error("Invalid unit " .. unit)
  end

  local result = {
    value = value,
    unit = unit,
  }
  setmetatable(result, self._mt)

  return result
end

function UnitSize:Parse(str, init)
  local match = string.match(str, "(%d+)([%%%a]*)()", init)
  if not match then
    -- invalid string
    return nil
  end

  local unit = self.UnitAliases[match[2]]
  if not unit then
    -- invalid unit
    return nil
  end

  return self:new(tonumber(match[1]), unit), match[3]
end

sgui.UnitSize = UnitSize

---
-- Constructs a @{UnitSize}.
-- @param number|string If a number is provided, it is the value, and the second parameter is the @{UnitSize.Unit}.
--                      If a string is provided, it is parsed, and the second parameter is an index to start parsing.
-- @param number The unit if a number is provided to the first argument, else the index to start parsing from.
-- @return UnitSize The constructed @{UnitSize}
function sgui.USize(value, unit)
  if type(value) == "string" then
    return UnitSize:Parse(value, unit)
  else
    return UnitSize:new(value, unit)
  end
end

function UnitSize:Resolve(props)
  if self.unit == UnitSize.Unit.Percent then
    if props.parentSize then
      return UnitSize:new(props.parentSize * self.value / 100)
    else
      -- don't have the info necessary for this
      return self
    end
  elseif self.unit == UnitSize.Unit.Em then
    if props.emSize then
      return UnitSize:new(props.emSize * self.value)
    else
      -- don't have the info necessary for this
      return self
    end
  else
    return self
  end
end

---
-- @class Expression
local Expression = {}

Expression.Op = {
  Add = 1,
  Sub = 2,
}

Expression.OpNames = {
  [Expression.Op.Add] = "+",
  [Expression.Op.Sub] = "-",
}

Expression.OpAliases = {
  ["+"] = Expression.Op.Add,
  ["-"] = Expression.Op.Sub,
}

Expression._mt = {
  __index = Expression,
  __tostring = function(self)
    return "(" .. self.left .. " " .. Expression.OpNames[self.op] .. " " .. self.right .. ")"
  end
}

function Expression:new(left, op, right)
  local function CheckExprTy(expr)
    if type(expr) ~= "table" then
      error("expected table, got " .. type(expr))
    end

    local mt = getmetatable(expr)
    if mt ~= Expression._mt and mt ~= UnitSize._mt then
      error("expected Expression or UnitSize")
    end
  end

  CheckExprTy(left)
  CheckExprTy(right)

  if not self.OpNames[op] then
    error("invalid op " .. op)
  end

  local result = {
    left = left,
    op = op,
    right = right,
  }
  setmetatable(result, self._mt)
  return result
end

-- TODO: parse expression

sgui.Expression = Expression

function Expression:Resolve(props)
  local l = self.left:Resolve(props)
  local r = self.right:Resolve(props)

  if
    getmetatable(l) == UnitSize._mt
    and getmetatable(r) == UnitSize._mt
    and l.unit == r.unit
  then
    -- both sides are sizes and have the same units, we can combine them
    local finalVal
    if self.op == Expression.Op.Add then
      finalVal = l.value + r.value
    elseif self.op == Expression.Op.Sub then
      finalVal = l.value - r.value
    end
    return UnitSize:new(finalVal, l.unit)
  end

  -- we need to create a new Expression
  if l == self.left and r == self.right then
    -- same values, return self
    return self
  end

  -- otherwise, construct new copy
  return Expression:new(l, self.op, r)
end
