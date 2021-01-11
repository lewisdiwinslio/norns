--- osc device
-- @module osc

local tab = require 'tabutil'
local paramset = require 'core/paramset'
local util = require 'util'

local OSC = {}
OSC.__index = OSC

--- static callback when an osc event is received.
-- user scripts can redefine.
-- @static
-- @tparam string path : osc message path
-- @tparam string args : osc message args
-- @tparam table from : a {host, port} table with the source address
function OSC.event(path, args, from)
  print("incoming osc message from", from, path)
  tab.print(args)
end

--- static method to send osc event.
-- @tparam table to : a {host, port} table with the destination address
-- @tparam string path : osc message path
-- @tparam string args : osc message args
function OSC.send(to, path, args)
  if (args ~= nil) then
    _norns.osc_send(to, path, args)
  else
    _norns.osc_send(to, path)
  end
end

-- FIXME: does this go to crone or sclang?
-- static method to send osc event directly to sclang.
-- @tparam string path : osc message path
-- @tparam string args : osc message args
function OSC.send_crone(path, args)
  if (args ~= nil) then
    _norns.osc_send_crone(path, args)
  else
    _norns.osc_send_crone(path)
  end
end

local function param_handler(path, args)
  local address_parts = {}
  local osc_pset_id = ""
  local osc_param_id
  local osc_param_value

  for part in path:gmatch("[^/]+") do
    table.insert(address_parts, part)
  end

  if 1 < #address_parts and #address_parts < 4 then
    if #address_parts == 3 then
      osc_pset_id = address_parts[2]
      osc_param_id = address_parts[3]
    else
      osc_param_id = address_parts[2]
    end

    osc_param_value = args[1]
    if osc_param_value == nil then
      error("osc parameter value is not set")
    end

    for pset_id, pset in pairs(paramset.sets) do
      if pset_id == osc_pset_id then
        local param = pset:lookup_param(osc_param_id)

        if param.id == osc_param_id then
          print('setting parameter '..pset_id..'/'..param.id..' to '..osc_param_value)
          param:set(osc_param_value)
        end
      end
    end
  end
end

local function remote_handler(path, args)
  if path=="/remote/key" then
    if args[1] and args[2] then _norns.key(args[1],args[2]) end
  elseif path=="/remote/enc" then
    if args[1] and args[2] then _norns.enc(args[1],args[2]) end
  end
end

-- handle an osc event.
_norns.osc.event = function(path, args, from)
  if util.string_starts(path, "/param") then
    param_handler(path, args)
  elseif util.string_starts(path, "/remote") then
    remote_handler(path, args)
  end

  if OSC.event ~= nil then OSC.event(path, args, from) end
end

return OSC
