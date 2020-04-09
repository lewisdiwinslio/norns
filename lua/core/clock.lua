--- clock coroutines
-- @module clock

local clock = {}

clock.threads = {}

local clock_id_counter = 1
local function new_id()
  local id = clock_id_counter
  clock_id_counter = clock_id_counter + 1
  return id
end

--- create a coroutine from the given function and immediately run it;
-- the function parameter is a task that will suspend when clock.sleep and clock.sync are called inside it and will wake up again after specified time.
-- @tparam function f
-- @treturn integer : coroutine ID that can be used to stop it later
clock.run = function(f)
  local coro = coroutine.create(f)
  local coro_id = new_id()
  clock.threads[coro_id] = coro
  clock.resume(coro_id)
  return coro_id
end

--- stop execution of a coroutine started using clock.run.
-- @tparam integer coro_id : coroutine ID
clock.cancel = function(coro_id)
  _norns.clock_cancel(coro_id)
  clock.threads[coro_id] = nil
end

local SLEEP = 0
local SYNC = 1


--- yield and schedule waking up the coroutine in s seconds;
-- must be called from within a coroutine started with clock.run.
-- @tparam float s : seconds
clock.sleep = function(...)
  return coroutine.yield(SLEEP, ...)
end


--- yield and schedule waking up the coroutine at beats beat;
-- the coroutine will suspend for the time required to reach the given fraction of a beat;
-- must be called from within a coroutine started with clock.run.
-- @tparam float beats : next fraction of a beat at which the coroutine will be resumed. may be larger than 1.
clock.sync = function(...)
  return coroutine.yield(SYNC, ...)
end

-- todo: use c api instead
clock.resume = function(coro_id)
  local coro = clock.threads[coro_id]

  if coro == nil then
    return -- todo: report error
  end

  local result, mode, time = coroutine.resume(clock.threads[coro_id])

  if coroutine.status(coro) == "dead" and result == false then
    error(mode)
  end

  if coroutine.status(coro) ~= "dead" and result and mode ~= nil then
    if mode == SLEEP then
      _norns.clock_schedule_sleep(coro_id, time)
    else
      _norns.clock_schedule_sync(coro_id, time)
    end
  end
end


clock.cleanup = function()
  for id, coro in pairs(clock.threads) do
    if coro then
      clock.cancel(id)
    end
  end

  clock.transport.start = nil
  clock.transport.stop = nil
end

--- select the sync source
-- @tparam string source : "internal", "midi", or "link"
clock.set_source = function(source)
  if type(source) == "number" then
    _norns.clock_set_source(util.clamp(source-1,0,3)) -- lua list is 1-indexed
  elseif source == "internal" then
    _norns.clock_set_source(0)
  elseif source == "midi" then
    _norns.clock_set_source(1)
  elseif source == "link" then
    _norns.clock_set_source(2)
  else
    error("unknown clock source: "..source)
  end
end


clock.get_beats = function()
  return _norns.clock_get_time_beats()
end

clock.get_tempo = function()
  return _norns.clock_get_tempo()
end


clock.transport = {}

clock.transport.start = nil
clock.transport.stop = nil


clock.internal = {}

clock.internal.set_tempo = function(bpm)
  return _norns.clock_internal_set_tempo(bpm)
end

clock.internal.start = function()
  return _norns.clock_internal_start()
end

clock.internal.stop = function()
  return _norns.clock_internal_stop()
end


clock.midi = {}


clock.link = {}

clock.link.set_tempo = function(bpm)
  return _norns.clock_link_set_tempo(bpm)
end

clock.link.set_quantum = function(quantum)
  return _norns.clock_link_set_quantum(quantum)
end


_norns.clock.start = function()
  if clock.transport.start ~= nil then
    clock.transport.start()
  end
end

_norns.clock.stop = function()
  if clock.transport.stop ~= nil then
    clock.transport.stop()
  end
end


function clock.add_params()
  params:add_group("CLOCK",7)
  
  params:add_option("clock_source", "source", {"internal", "midi", "link", "crow"})
  params:set_action("clock_source", 
    function(x)
      clock.set_source(x)
      if x==4 then
        crow.input[1].change = function() end
        crow.input[1].mode("change",2,0.1,"rising")
      end
    end)
  params:add_number("clock_tempo", "tempo", 1, 300, 120)
  params:set_action("clock_tempo",
    function(bpm) 
      local source = params:string("clock_source")
      if source == "internal" then clock.internal.set_tempo(bpm)
      elseif source == "link" then clock.link.set_tempo(bpm) end
    end)
  params:add_trigger("clock_reset", "reset")
  params:set_action("clock_reset",
    function(bpm) 
      local source = params:string("clock_source")
      if source == "internal" then clock.internal.start(bpm)
      elseif source == "link" then print("link reset not supported") end
    end)
  params:add_number("link_quantum", "link quantum", 1, 20, 4)
  params:set_action("link_quantum",
    function(x) clock.link.set_quantum(x) end)

  params:add_option("clock_midi_out", "midi out",
      {"off", "port 1", "port 2", "port 3", "port 4"})
  params:add_option("clock_crow_out", "crow out",
      {"off", "output 1", "output 2", "output 3", "output 4"})
  params:set_action("clock_crow_out", function(x)
      if x>1 then crow.output[x-1].action = "pulse(0.05,8)" end
    end)
  params:add_number("clock_crow_out_div", "crow out div", 1, 32, 4)

  -- executes crow sync
  clock.run(function()
    while true do
      clock.sync(1/params:get("clock_crow_div"))
      local crow_out = params:get("clock_crow_out")-1
      if crow_out > 0 then crow.output[crow_out]() end
    end
  end)

  -- executes midi out (needs a subtick)
  -- FIXME: lots of if's every tick blah
  clock.run(function()
    while true do
      clock.sync(1/24)
      local midi_out = params:get("clock_midi_out")-1
      if midi_out > 0 then 
        if midi.vports[midi_out].name ~= "none" then
          midi.vports[midi_out]:clock()
        end 
      end
    end
  end)

end


return clock
