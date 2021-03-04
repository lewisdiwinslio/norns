local m = {
  pos = 1,
  list = {"SELECT", "SYSTEM", "SLEEP"}
}

m.init = function()
  _menu.timer.time = 1
  _menu.timer.count = -1
  _menu.timer.event = function() _menu.redraw() end
  _menu.timer:start()
end

m.deinit = function()
  _menu.timer:stop()
end

m.key = function(n,z)
  if n == 2 and z == 1 then
    _menu.showstats = not _menu.showstats
    _menu.redraw()
  elseif n == 3 and z == 1 then
    if _menu.alt == false then
      _menu.set_page(m.list[m.pos])
    else
      norns.script.clear()
      _norns.free_engine()
      _menu.m["PARAMS"].reset()
      _menu.locked = true
    end
  end
end

m.enc = function(n,delta)
  if n == 2 then
    m.pos = util.clamp(m.pos + delta, 1, #m.list)
    _menu.redraw()
  end
end

m.redraw = function()
  screen.clear()
  _menu.draw_panel()
  for i=1,3 do
    screen.move(0,25+10*i)
    if(i==m.pos) then
      screen.level(15)
    else
      screen.level(4)
    end
    screen.text(m.list[i].." >")
  end

  if not _menu.showstats then
    screen.move(0,15)
    screen.level(15)
    local line = string.upper(norns.state.name)
    if(_menu.scripterror and _menu.errormsg ~= 'NO SCRIPT') then
      line = "error: " .. _menu.errormsg
    end
    screen.text(line)
  else
    screen.level(1)
    if norns.is_norns then
      screen.move(127,55)
      screen.text_right(norns.battery_current.."mA @ ".. norns.battery_percent.."%")
      --screen.move(36,10)
      --screen.text(norns.battery_current .. "mA")
    end
    screen.move(0,10) screen.text("cpu")
    screen.move(30,10) screen.text_right(norns.cpu[1]..".")
    screen.move(45,10) screen.text_right(norns.cpu[2]..".")
    screen.move(60,10) screen.text_right(norns.cpu[3]..".")
    screen.move(75,10) screen.text_right(norns.cpu[4]..".")
    screen.move(127,10)
    screen.text_right(norns.temp .. "c")

    screen.move(0,20)
    screen.text("disk " .. norns.disk .. "M")
    screen.move(127,20)
    if wifi.state > 0 then
      screen.text_right(wifi.ip)
    end
    screen.move(127,45)
    screen.text_right(norns.version.update)

    screen.level(15)
    screen.move(127,35)
    screen.text_right(string.upper(norns.state.name))
  end

  if _menu.alt==true and m.pos==1 then
    screen.clear()
    screen.move(64,40)
    screen.level(15)
    screen.text_center("CLEAR")
  end

  screen.update()
end

return m
