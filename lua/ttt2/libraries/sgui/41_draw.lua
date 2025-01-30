
local util = util
local draw = draw
local surface = surface

local sgui = sgui
local sgui_local = sgui_local
local sdraw = sgui.draw
local sldraw = sgui_local.draw

local PaintContext = sgui_local.PaintContext
local GetId = sgui_local.GetId
local GetClipRect = sgui_local.GetClipRect

-- TODO: scaling

function sgui.draw.Box(x_, y_, w, h, color_)
  local ctx = PaintContext.Get()
  w, h = sdraw.ConvertSize(w, h)
  ctx:RecWithState(x_, y_, function(x, y, color)
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    surface.DrawRect(x, y, w, h)
  end, color_)
end

function sgui.draw.ShadowedBox(x_, y_, w, h, color_, scale)
  scale = scale or 1
  local ctx = PaintContext.Get()
  w, h, scale = sdraw.ConvertSize(w, h, scale)
  ctx:RecWithState(x_, y_, function(x, y, color)
    draw.ShadowedBox(x, y, w, h, color, scale)
  end, color_)
end

function sgui.draw.RoundedBox(r, x_, y_, w, h, color_)
  local ctx = PaintContext.Get()
  r, w, h = sdraw.ConvertSize(r, w, h)
  ctx:RecWithState(x_, y_, function(x, y, color)
    draw.RoundedBox(r, x, y, w, h, color)
  end, color_)
end

function sgui.draw.OutlinedBox(x_, y_, w, h, t, color_)
  local ctx = PaintContext.Get()
  w, h = sdraw.ConvertSize(w, h)
  ctx:RecWithState(x_, y_, function(x, y, color)
    draw.OutlinedBox(x, y, w, h, t, color)
  end, color_)
end

function sgui.draw.OutlinedShadowedBox(x_, y_, w, h, t, color_)
  local ctx = PaintContext.Get()
  w, h = sdraw.ConvertSize(w, h)
  ctx:RecWithState(x_, y_, function(x, y, color)
    draw.OutlinedShadowedBox(x, y, w, h, t, color)
  end, color_)
end

function sgui.draw.OutlinedCircle(x_, y_, r, color_)
  local ctx = PaintContext.Get()
  color_ = color_ or COLOR_WHITE
  r = sdraw.ConvertSize(r)
  ctx:RecWithState(x_, y_, function(x, y, color)
    surface.DrawCircle(x, y, r, color.r, color.g, color.b, color.a)
  end)
end

function sgui.draw.OutlinedShadowedCircle(x_, y_, r, color_, scale)
  scale = scale or 1
  local ctx = PaintContext.Get()
  r, scale = sdraw.ConvertSize(r, scale)
  ctx:RecWithState(x_, y_, function(x, y, color)
    draw.OutlinedShadowedCircle(x, y, r, color, scale)
  end, color_)
end

function sgui.draw.Circle(x_, y_, r, color_)
  local ctx = PaintContext.Get()
  r = sdraw.ConvertSize(r)
  ctx:RecWithState(x_, y_, function(x, y, color)
    draw.Circle(x, y, r, color)
  end, color_)
end

function sgui.draw.ShadowedCircle(x_, y_, r, color_, scale)
  scale = scale or 1
  local ctx = PaintContext.Get()
  r, scale = sdraw.ConvertSize(r, scale)
  ctx:RecWithState(x_, y_, function(x, y, color)
    draw.ShadowedCircle(x, y, r, color, scale)
  end, color_)
end

function sgui.draw.Line(x1, y1, x2, y2, color_)
  x1, y1 = sdraw.ConvertCoords(x1, y1)
  x2, y2 = sdraw.ConvertCoords(x2, y2)

  local ctx = PaintContext.Get()
  ctx:RecordDraw(GetId(), 0, 0, function(x, y, color)
    draw.Line(x + x1, y + y1, x + x2, y + y2, color)
  end, color_)
end

function sgui.draw.ShadowedLine(x1, y1, x2, y2, color_)
  x1, y1 = sdraw.ConvertCoords(x1, y1)
  x2, y2 = sdraw.ConvertCoords(x2, y2)

  local ctx = PaintContext.Get()
  ctx:RecordDraw(GetId(), 0, 0, function(x, y, color)
    draw.ShadowedLine(x + x1, y + y1, x + x2, y + y2, color)
  end, color_)
end

function sgui.draw.Texture(x_, y_, w, h, material_, alpha, color)
  w, h = sdraw.ConvertSize(w, h)
  local ctx = PaintContext.Get()
  ctx:RecWithState(x_, y_, function(x, y, material)
    draw.Texture(x, y, w, h, material, alpha, color)
  end, material_)
end

function sgui.draw.ShadowedTexture(x_, y_, w, h, material_, alpha, color, scale)
  scale = scale or 1
  w, h, scale = sdraw.ConvertSize(w, h, scale)
  local ctx = PaintContext.Get()
  ctx:RecWithState(x_, y_, function(x, y, material)
    draw.ShadowedTexture(x, y, w, h, material, alpha, color, scale)
  end, material_)
end

function sgui.draw.FilteredTexture(x_, y_, w, h, material_, alpha, color)
  w, h = sdraw.ConvertSize(w, h)
  local ctx = PaintContext.Get()
  ctx:RecWithState(x_, y_, function(x, y, material)
    draw.FilteredTexture(x, y, w, h, material, alpha, color)
  end, material_)
end

function sgui.draw.FilteredShadowedTexture(x_, y_, w, h, material_, alpha, color, scale)
  scale = scale or 1
  w, h, scale = sdraw.ConvertSize(w, h, scale)
  local ctx = PaintContext.Get()
  ctx:RecWithState(x_, y_, function(x, y, material)
    draw.FilteredShadowedTexture(x, y, w, h, material, alpha, color, scale)
  end, material_)
end

-- TODO: BlurredBox

-- TODO: text
