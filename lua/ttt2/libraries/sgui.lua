---
-- SGUI, a declarative, scalable, UI system built on Derma and VGUI
-- @author DaNike
-- @module sgui
-- @realm client

local sguiFilePrefix = "ttt2/libraries/sgui/"
local sguiFiles = {
  "00_enums",
  "10_registry",
  "20_element",
  "99_vgui"
}

if SERVER then
  AddCSLuaFile()
  for i = 1, #sguiFiles do
    AddCSLuaFile(sguiFilePrefix .. sguiFiles[i] .. ".lua")
  end
  return
end

local sgui_local = sgui_local
_G.sgui_local = {}
sgui = sgui or {}

-- Include all sgui external modules afterwards
for i = 1, #sguiFiles do
  include(sguiFilePrefix .. sguiFiles[i] .. ".lua")
end

_G.sgui_local = sgui_local
