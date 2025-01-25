---
-- SGUI Layout code
--

local sgui = sgui

local function InstantiateElement(desc)

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

    if type(k) == "string" then
      -- an option, record it in the options table
      options[k] = v
    elseif type(k) == "number" then
      -- a child, record it in the children table
      children[k] = v
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

    local resultOptsHasAny = false
    for _,_ in pairs(result.options) do
      resultOptsHasAny = true
      break
    end

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

    return { cls = elemCls, options = options, children = children2  }
  end
end
