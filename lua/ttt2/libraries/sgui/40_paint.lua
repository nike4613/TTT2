
local math = math
local util = util

local sgui = sgui
local sgui_local = sgui_local

local PAINT_KIND_DRAW = 1
local PAINT_KIND_CLIP = 2
local PAINT_KIND_MAT = 3

local PaintContext = {}
PaintContext.mt = {__index=PaintContext}
function PaintContext:new()
  local result = {}
  setmetatable(result, PaintContext.mt)

  result.drawList = {}
  result.lastClip = nil
  result.lastMat = nil

  return result
end

function PaintContext:RecordDraw(id, x, y, func, obj)
  self.drawList[#self.drawList + 1] = {
    kind = PAINT_KIND_DRAW,
    id = id,
    x = x,
    y = y,
    func = func,
    obj = obj
  }
end

function PaintContext:EnsureClipRect(rect)
  if self.lastClip ~= rect then
    self.drawList[#self.drawList + 1] = {
      kind = PAINT_KIND_CLIP,
      rect = rect
    }
    self.lastClip = rect
  end
end

function PaintContext:EnsureMat(mat)
  if self.lastMat ~= mat then
    self.drawList[#self.drawList + 1] = {
      kind = PAINT_KIND_MAT,
      mat = mat
    }
    lastMat = mat
  end
end


function PaintContext:ClearDraws()
  self.lastClip = nil
  self.lastMat = nil
  for k in pairs(self.drawList) do
    self.drawList[k] = nil
  end
end

sgui_local.PaintContext = PaintContext

local idMat = Matrix()
idMat:Identity()

local contextStack = {}
local clipStackCtxDepth = {}
local matStackCtxDepth = {}
local clipStack = {}
local matStack = {}

local function GetClipRect()
  return clipStack[#clipStack]
end

local function PushClipRect(rect)
  clipStack[#clipStack + 1] = rect
end

local function PopClipRect()
  clipStack[#clipStack] = nil
end

local function GetMat()
  return matStack[#matStack]
end

local function PushMat(mat)
  matStack[#matStack + 1] = mat
end

local function PopMat()
  matStack[#matStack] = nil
end

function PaintContext:Push(w, h)
  contextStack[#contextStack + 1] = self

  -- reset ambient render state used to build the draw list
  self.lastClip = { x = 0, y = 0, w = w, h = h }
  self.lastMat = nil
  PushClipRect(self.lastClip)
  PushMat(idMat)

  clipStackCtxDepth[#clipStackCtxDepth + 1] = #clipStack
  matStackCtxDepth[#matStackCtxDepth + 1] = #matStack
end

function PaintContext:Pop()
  -- pop the correct clip stack depth
  local targetDepth = clipStackCtxDepth[#clipStackCtxDepth]
  clipStackCtxDepth[#clipStackCtxDepth] = nil

  -- then pop the clip stack down to that point
  while #clipStack >= targetDepth do
    clipStack[#clipStack] = nil
  end

  -- and do the same for the mat stack
  targetDepth = matStackCtxDepth[#matStackCtxDepth]
  matStackCtxDepth[#matStackCtxDepth] = nil
  while #matStack >= targetDepth do
    matStack[#matStack] = nil
  end

  -- finally, actually pop the context
  contextStack[#contextStack] = nil
end

function PaintContext.Get()
  return contextStack[#contextStack]
end

sgui.draw = sgui.draw or {}
local sdraw = sgui.draw

---
-- Pushes a new clip rect to the stack.
-- @param x number The X coordinate (relative to the current clip-rect) of the top-left corner of the new rect.
-- @param y number The Y coordinate (relative to the current clip-rect) of the top-left corner of the new rect.
-- @param w number|nil The width of the new clip rect. If not provided, the remaining space in the parent clip rect will be used instead.
-- @param h number|nil The height of the new clip rect. If not provided, the remaining space in the parent clip rect will be used instead.
-- @see @{sgui.draw.PopClipRect}
-- @realm client
function sgui.draw.PushClipRect(x, y, w, h)
  local cur = GetClipRect()
  x = math.min(x, cur.w)
  y = math.min(y, cur.h)
  w = w or cur.w
  h = h or cur.h
  PushClipRect({
      x = cur.x + x,
      y = cur.y + y,
      w = math.min(w, cur.w - x),
      h = math.min(h, cur.h - y),
  })
end

---
-- Pops the current clip rect from the stack.
-- @see @{sgui.draw.PushClipRect}
-- @realm client
function sgui.draw.PopClipRect()
  -- don't pop clip rects past the current context depth
  if #clipStack > clipStackCtxDepth[#clipStackCtxDepth] then
    PopClipRect()
  end
end

---
-- Pushes a new transformation matrix to the stack, optionally multiplying by the current matrix first.
-- @param mat VMatrix The matrix to push to the stack.
-- @param multiply boolean[default=true] If set to true (as is default), post-multiplies @{mat} by the current matrix before pushing.
-- @see @{sgui.draw.PopMatrix}
-- @realm client
function sgui.draw.PushMatrix(mat, multiply)
  if multiply == nil then multiply = true end

  if multiply then
    mat = GetMat() * mat
  end

  PushMat(mat)
end

---
-- Pops the current transformation matrix off of the stack.
-- @see @{sgui.draw.PushMatrix}
-- @realm client
function sgui.draw.PopMatrix()
  -- similar to PopClipRect, make sure we don't pop past the current context depth
  if #matStack > matStackCtxDepth[#matStackCtxDepth] then
    PopMat()
  end
end
