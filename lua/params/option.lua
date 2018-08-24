--- Option class
-- @module option

local tab = require 'tabutil'

local Option = {}
Option.__index = Option

local tOPTION = 2

function Option.new(name, options, default)
  local o = setmetatable({}, Option)
  o.t = tOPTION
  o.name = name
  o.options = {}
  for k,v in pairs(options) do
    o.options[k] = v
  end
  o.count = tab.count(o.options)
  o.default = default or 1
  o.selected = o.default
  o.action = function() end
  return o
end

function Option:get()
  return self.selected
end

function Option:set(v)
  local c = util.clamp(v,1,self.count)
  if self.selected ~= c then
    self.selected = c
    self:bang()
  end
end

function Option:delta(d)
  self:set(self:get() + d)
end

function Option:set_default()
  self:set(self.default)
end

function Option:bang()
  self.action(self.selected)
end

function Option:string()
  return self.options[self.selected]
end


return Option
