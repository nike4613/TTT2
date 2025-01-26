---
-- SGUI Layout code
--

local sgui = sgui

local function BuildRealTree(path, tree, params)
  local elemTy = tree.type or tree.ty
  if not elemTy and tree.vgui then
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

  for k,v in pairs(tree) do
    if k == "type" or k == "ty" then
      continue -- skip the type descriminator
    end

    if type(v) == "table" and v.param ~= nil then
      if not params then
        error("invalid tree: invalid param=" .. v.param .. ": not in sgui element def at " .. path)
      end
      if type(v.param) == "number" then
        -- a { param=1 } expands to the first child, { param=2 } expands to the second, etc
        v = params.children[v.param]
      end
      if type(v.param) == "string" then
        v = params.opts[v.param]
      end
    end

    if type(k) == "string" then
      -- an option, record it in the options table
      options[k] = v
    elseif type(k) == "number" then
      -- a child, record it in the children table
      if type(v) == "table" and v.template == "children" then
        -- a { template="children" } expands to the list of children specified in the referent
        if not params then
          error("invalid tree: invalid template=children: not in sgui element def at " .. path)
        end

        for i = 1, #params.children do
          table.insert(children, params.children[i])
        end
        continue
      end

      if v then
        table.insert(children, v)
      end
    end
  end

  -- now expand child trees as appropriate
  local thisPathIdx = #path + 1
  if getmetatable(elemCls) == sgui.SGUIElement.mt then
    -- this is an SGUIElement, grab the definition and instantiate it
    local def = elemCls.definition
    path[thisPathIdx] = elemTy
    local result = BuildRealTree(path, def, { opts = options, children = children })
    path[thisPathIdx] = nil

    local resultOptsHasAny = next(result.options) ~= nil

    if not resultOptsHasAny then
      -- if the options of the root element aren't present, use the ones passed in to this element
      result.options = options
    end

    return result
  else
    -- this is some other kind of node, visit children and construct result
    local children2 = {}
    for i,c in ipairs(children) do
      path[thisPathIdx] = i
      table.insert(children2, BuildRealTree(path, c, params))
    end
    path[thisPathIdx] = nil

    return { cls = elemCls, path = tostring(path), options = options, children = children2  }
  end
end

local function MakePathTbl()
  local tbl = {}
  setmetatable(tbl, {
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
  })
  return tbl
end

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

local function CacheClassInstances(cache, cacheInfo, tree)
  -- start by looking up the instance in the cache
  local key = tree.path
  local cached = cache[key]

  local inst
  if cached then
    -- we have a cached instance, only reuse if the options are the same

    if TableEq(tree.options, cached.opt) then
      -- option tables are equal, can reuse
      inst = cached.inst
    else
      -- cannot reuse
      cacheInfo:RemoveCached(cached)
      inst = nil
    end
  end

  if not inst then
    -- no cached instance, need to create
    inst = {}
    setmetatable(inst, tree.cls.mt)
    inst:Init(tree.options)
    local id = cacheInfo:NextId()
    cache[key] = { inst = inst, opt = tree.options, id = id }
  end

  -- stash the created instance in
  tree.inst = inst

end
