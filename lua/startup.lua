-- STARTUP 

require 'menu'

require 'math' 
math.randomseed(os.time()) -- more random

-- globals
screen = require 'screen'
grid = require 'grid'
hid = require 'hid'
metro = require 'metro'
midi = require 'midi'
osc = require 'osc'
poll = require 'poll'
engine = require 'engine'
wifi = require 'wifi'

fileselect = require 'fileselect'
textentry = require 'textentry'

controlspec = require 'controlspec'
paramset = require 'paramset' 

params = paramset.new()

tab = require 'tabutil'
util = require 'util'

-- management of grids
g = nil

grid.add = function(device)
  print("attaching grid ")
  g = device
  g.key = gridkey
  g:print()
  norns.log.post("connected: grid")
end

grid.reconnect = function()
   print("grid.reconnect (default)")
  _, g = next(grid.devices) -- hacky way to get basically random item in a table
  if g then
     grid.add(g)
  end
end

grid.remove = function(device) g = nil end


norns.startup_status.ok = function()
  print("norns.startup_status.ok")
  -- resume last loaded script
  norns.log.post("norns started")
  norns.script.resume()
end

norns.startup_status.timeout = function()
  print("norns.startup_status.timeout")
  norns.script.error("AUDIO ENGINE")
end


-- check for pending updates
norns.update.run()

--print("start_audio(): ")
-- start the process of syncing with crone boot
start_audio()
