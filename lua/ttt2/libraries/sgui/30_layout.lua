---
-- SGUI Layout code
--

local sgui = sgui
local sgui_local = sgui_local

local function TableEq(o1, o2)
  if o1 == o2 then return true end
  local o1Type = type(o1)
  local o2Type = type(o2)
  if o1Type ~= o2Type then return false end
  if o1Type ~= 'table' then return false end

  local keySet = {}

  for key1, value1 in pairs(o1) do
    local value2 = o2[key1]
    if value2 == nil or TableEq(value1, value2) == false then
      return false
    end
    keySet[key1] = true
  end

  for key2, _ in pairs(o2) do
    if not keySet[key2] then return false end
  end
  return true
end

local Params = {}
function Params:new(options, children)
  local result = { options = options, children = children }
  setmetatable(result, {__index=self})
  return result
end

function Params:Resolve(value)
  if type(value) ~= "table" then
    return value
  end

  local k, v = next(value)
  if not next(value, k) and k == "param" then
    -- this has the form {param="name"}, resolve the name from options
    return self.options[v]
  end

  -- otherwise, it's just the value again
  return value
end

sgui_local.Params = Params

local function RebuildCache(cache, cacheTree, path, declTree, params)
 local elemTy = declTree.type or declTree.ty
  if not elemTy and declTree.vgui then
    elemTy = "vgui"
  end

  if not elemTy or type(elemTy) ~= "string" then
    error("invalid tree: invalid type " .. (elemTy or "(nil)") .. " at " .. path)
  end

  -- lookup the element class by the declared type
  local elemCls = sgui.GetElement(elemTy)
  if not elemCls then
    error("invalid tree: invalid node type " .. elemTy .. " at " .. path)
  end

  -- now separate the tree into options + children for easier processing down the line
  local options = {}
  local children = {}

  for k,v in pairs(declTree) do
    if k == "type" or k == "ty" then
      continue
    end

    if type(k) == "number" then
      -- child, treat accordingly
      if type(v) ~= "table" then
        error("invalid tree: child " .. k .. " is not a table at " .. path)
      end

      local isChildDecl = true
      if params then
        -- params is non-nil, so having param-children is acceptable
        if
          not (v.ty or v.type or v.vgui)
          and (v.template == "child" or v.template == "children")
        then
          -- this is a children template, look up params children and insert
          isChildDecl = false

          local resolvedFirst = params:Resolve(v.first)
          local resolvedIdx = params:Resolve(v.idx)
          local resolvedCount = params:Resolve(v.count)

          local first = resolvedFirst or resolvedIdx or 1
          local count = resolvedCount or (resolvedIdx and 1) -- becomes nil to count all, defaults to count=1 if idx is what was set
          local selectedChildren = {table.unpack(params.children, first, count and (first + count - 1))}
          children[k] = selectedChildren
        end
      end

      if isChildDecl then
        -- this is a child object declaration, process it
        local pathIdx = #path + 1
        path[pathIdx] = k
        local cacheChild = cacheTree.children[k] or { children = {} }
        cacheTree.children[k] = cacheChild
        local child = RebuildCache(cacheChild, path, v, params)
        children[k] = {child}
        path[pathIdx] = nil
      end
    else
      -- option, record it in our options table
      options[k] = params and params:Resolve(v) or v
    end
  end

  -- now here, create a flattened children list (in order)
  local flatChildren = {}
  for _,v in ipairs(children) do
    table.Add(flatChildren, v)
  end

  -- next, instantiate or reuse the existing instantiation
  local result = cacheTree.result
  local inst = result and result.inst
  if inst then
    -- we already have an instance, check if its usable
    if getmetatable(inst).__index == elemCls then
      -- same class, check options
      if not TableEq(cacheTree.options, options) then
        -- options differ, try update before re-creation
        if not inst:Update(options) then
          -- update returned false, need to recreate
          inst = nil
        end
      end
    else
      -- different class, need to recreate
      inst = nil
    end
  end

  result = result or {}

  if not inst then
    -- need to recreate the instance
    inst = {}
    setmetatable(inst, elemCls)
    inst:Init(options)

    local newId = cache:NextId() -- each instance we create gets a new unique id that we associate with draws for processing there
    -- tell the cache that we're replacing an id
    if result.id then
      cache:ReplaceId(result.id, newId)
    end
    result.id = cache:NextId()
  end

  -- now build up our result
  result.inst = inst
  result.children = flatChildren

  -- and cache it
  cacheTree.result = result
  cacheTree.options = options

  -- clear the cached children entries that we don't have anymore
  local l = #cacheTree.children + 1
  for i = 1, #cacheTree.children do
    local idx = l - i
    if not children[idx] then
      -- we're removing an object, so make sure to also remove its id
      cache:RemoveId(cacheTree.children[idx].id)
      cacheTree.children[idx] = nil
    end
  end

  -- and return
  return result
end

local pathMTbl = {
  __tostring = function(self)
    local str = "["
    for i = 1, #self do
      str = str .. "." .. tostring(self[i])
    end
    return str .. "]"
  end,
  __eq = function(l, r)
    if #l ~= #r then
      return false
    end
    for i = 1, #l do
      if l[i] ~= r[i] then
        return false
      end
    end
    return true
  end
}
local function MakePathTbl()
  local tbl = {}
  setmetatable(tbl, pathMTbl)
  return tbl
end


local Cache = {}
function Cache:new()
  local result = {}
  setmetatable(result, {__index=self})

  result.nextId = 1
  result.tree = nil
  result.treeCache = {}
  result.drawListChanges = {}
  result.drawList = {}

  return result
end

function Cache:NextId()
  local result = self.nextId
  self.nextId = result + 1
  return result
end

function Cache:Update(tree, params)
  local path = MakePathTbl()
  self.tree = RebuildCache(self, self.treeCache, path, tree, params)
  return self.tree
end

function Cache:RemoveId(id)
  -- TODO: mark id removal somehow reasonable
end

function Cache:ReplaceId(oldId, newId)
  -- TODO: mark id replacement somehow reasonably
end

sgui_local.Cache = Cache
