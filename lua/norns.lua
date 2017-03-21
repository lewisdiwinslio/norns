--[[
   norns.lua
   startup script for norns lua environment.

   NB: removal of any function/module definitions will break the C->lua glue.
   in other respects, feel free to customize.
--]]

version = {}
version.norns = "0.0.1"

print("running norns.lua")

-- utilities and helpers
dofile('lua/helpers.lua')
dofile('lua/monome.lua')
dofile('lua/input.lua')

-- this function will be run after I/O subsystems are initialized,
-- but before I/O event loop starts ticking
startup = function()
   -- define your own startup routine here
   -- ( likely just: dofile("mycustomscript.lua") )

   -- joystick and sinewave demo
   -- dofile('lua/sticksine.lua')

   -- test timer stuff
   -- dofile('lua/timertest.lua')

   -- joystick and sample cutter demo
   -- dofile('lua/stickcut.lua')

   -- testing grid/timer sequence
   -- dofile('lua/test128.lua')

end

--------------------------
-- define default event handlers.
-- user scripts should redefine.

-- tbale of encoder event handlers
encoder = {}
--...

-- table of button event handlers
button = {}
--...

-- table of grid event handlers
--[[
grid = {}
grid.press = function(x, y)
   print ("press " .. x .. " " .. y)
   grid_set_led(x, y, 1);
end

grid.lift = function(x, y)
   print ("lift " .. x .. " " .. y)
   grid_set_led(x, y, 0);
end

grid.connect = function()
   print ("grid connect ")
end

grid.disconnect = function()
   print ("grid disconnect ")
end

-- arc
--...
--]]

-- table of joystick event handlers
joystick = {}

joystick.axis = function(stick, ax, val)
   print("stick " .. stick .. "; axis " .. ax .. "; value " .. val)
end

joystick.button = function(stick, but, state)
   print("stick " .. stick .. "; button " .. but .. "; state " .. state)
end

joystick.hat = function(stick, hat, val)
   print("stick " .. stick .. "; hat " .. hat .. "; value " .. val)
end

joystick.ball = function(stick, ball, xrel, yrel)
   print("stick " .. stick .. "; ball " .. ball .. "; xrel " .. xrel .. "; yrel " .. yrel)
end

-- mouse/KB
--...

-- MIDI
-- ...

-- table

-- table of handlers for descriptor reports
report = {}

report.engines = function(names, count)
   print(count .. " engines: ")
   for i=1,count do
	  print(i .. ": "..names[i])
   end
end

report.commands = function(commands, count)
   addEngineCommands(commands, count)
end

-- table of engine commands
engine = {}
-- shortcut
e = engine

-- timer handler
timer = function(idx, stage)
   print("timer " .. idx .. " stage " .. stage)
end

versions = function()
  for key,value in pairs(version) do
    print(key .. ": "  .. value)
  end
end
