--- ParamSet class
-- @module paramset

local separator = require 'params/separator'
local number = require 'params/number'
local option = require 'params/option'
local control = require 'params/control'
local file = require 'params/file'
local taper = require 'params/taper'

local ParamSet = {
  tSEPARATOR = 0,
  tNUMBER = 1,
  tOPTION = 2,
  tCONTROL = 3,
  tFILE = 4,
  tTAPER = 5,
}

ParamSet.__index = ParamSet

--- constructor
-- @param name
function ParamSet.new(name)
  local ps = setmetatable({}, ParamSet)
  ps.name = name or ""
  ps.params = {}
  ps.count = 0
  ps.lookup = {}
  return ps
end

--- add separator
function ParamSet:add_separator()
  table.insert(self.params, separator.new())
  self.count = self.count + 1
end

--- add number
function ParamSet:add_number(name, min, max, default)
  table.insert(self.params, number.new(name, min, max, default))
  self.count = self.count + 1
  self.lookup[name] = self.count
end

--- add option
function ParamSet:add_option(name, options, default)
  table.insert(self.params, option.new(name, options, default))
  self.count = self.count + 1
  self.lookup[name] = self.count
end

--- add control
function ParamSet:add_control(name, controlspec, formatter)
  table.insert(self.params, control.new(name, controlspec, formatter))
  self.count = self.count + 1
  self.lookup[name] = self.count
end

--- add file
function ParamSet:add_file(name, path)
  table.insert(self.params, file.new(name, path))
  self.count = self.count + 1
  self.lookup[name] = self.count
end

--- add taper
function ParamSet:add_taper(name, min, max, default, k, units)
  table.insert(self.params, taper.new(name, min, max, default, k, units))
  self.count = self.count + 1
  self.lookup[name] = self.count
end

--- print
function ParamSet:print()
  print("paramset ["..self.name.."]")
  for k,v in pairs(self.params) do
    print(k.." "..v.name.." = "..v:string())
  end
end

--- name
function ParamSet:get_name(index)
  return self.params[index].name
end

--- string
function ParamSet:string(index)
  if type(index) == "string" then index = self.lookup[index] end
  return self.params[index]:string()
end

--- set
function ParamSet:set(index, v)
  if type(index) == "string" then index = self.lookup[index] end
  self.params[index]:set(v)
end

--- get
function ParamSet:get(index)
  if type(index) == "string" then index = self.lookup[index] end
  return self.params[index]:get()
end

--- delta
function ParamSet:delta(index, d)
  if type(index) == "string" then index = self.lookup[index] end
  self.params[index]:delta(d)
end

--- set action
function ParamSet:set_action(index, func)
  if type(index) == "string" then index = self.lookup[index] end
  self.params[index].action = func
end

--- get type
function ParamSet:t(index)
  return self.params[index].t
end


 
--- write to disk
-- @param filename relative to data_dir
function ParamSet:write(filename) 
  local fd=io.open(data_dir .. filename,"w+")
  io.output(fd)
  for k,v in pairs(self.params) do
    io.write(k..","..v:get().."\n")
  end
  io.close(fd)
end

--- read from disk
-- @param filename relative to data_dir
function ParamSet:read(filename)
  local fd=io.open(data_dir .. filename,"r")
  if fd then
    io.close(fd)
    for line in io.lines(data_dir .. filename) do
      k,v = line:match("([^,]+),([^,]+)")
      if tonumber(v) ~= nil then
        self.params[tonumber(k)]:set(tonumber(v))
      elseif v then
        self.params[tonumber(k)]:set(v)
      end
    end 
  else print("paramset: " .. filename .. " not read.")
  end 
end

--- bang all params
function ParamSet:bang()
  for k,v in pairs(self.params) do
    v:bang()
  end
end 

--- clear
function ParamSet:clear()
  self.name = ""
  self.params = {}
  self.count = 0
end

return ParamSet
