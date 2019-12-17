--- Screen class
-- subset of cairo drawing functions. see https://www.cairographics.org/tutorial/
-- @classmod screen
-- @alias Screen
local Screen = {}

local metro = require 'core/metro'
local screensaver = metro[36]

local sleeping = false

screensaver.event = function()
  _norns.screen_clear()
  _norns.screen_update()
  sleeping = true
  Screen.update = function() end
end
screensaver.time = 900
screensaver.count = 1

--- copy buffer to screen.
Screen.update_default = function()
  _norns.screen_update()
end

--- restart screen saver timer
Screen.ping = function()
  screensaver:start()
  if sleeping == true then
    Screen.update = Screen.update_default
  end
end

--- low battery screen update
Screen.update_low_battery = function()
	_norns.screen_rect(32,34,64,16)
  _norns.screen_level(0)
  _norns.screen_fill()
  _norns.screen_move(64,45)
  _norns.screen_level(15)
  _norns.screen_text_center("LOW BATTERY")
  _norns.screen_update()  
end

Screen.update = Screen.update_default

--- enable/disable anti-aliasing.
-- @param state on(1) or off(0)
Screen.aa = function(state) _norns.screen_aa(state) end

--- clear.
Screen.clear = function() _norns.screen_clear() end

--- set level (color/brightness).
-- @param value 0-15 (0=off, 15=white)
Screen.level = function(value) _norns.screen_level(value) end

--- set line width.
-- @param w line width (in pixels, floats permitted)
Screen.line_width = function(w) _norns.screen_line_width(w) end

--- set line cap style.
-- @param style line cap style string ("butt", "round" or "square"). default is "butt".
Screen.line_cap = function(style)
  _norns.screen_line_cap(style)
end

--- set line join style.
-- @param style line join style string ("miter", "round" or "bevel"). default is "miter"
Screen.line_join = function(style)
  _norns.screen_line_join(style)
end

--- set miter limit.
-- @param limit if the current line join style is set to "miter", the miter limit is used to determine whether the lines should be joined with a bevel instead of a miter. if the length of the miter divided by the line width is greater than the miter limit, the style is converted to a bevel. default value 10.
Screen.miter_limit = function(limit)
  _norns.screen_miter_limit(limit)
end

--- move drawing position.
-- @param x position x
-- @param y position y
Screen.move = function(x, y) _norns.screen_move(x, y) end

--- move drawing position relative to current position.
-- @param x relative position x
-- @param y relative position y
Screen.move_rel = function(x, y) _norns.screen_move_rel(x, y) end

--- draw line to specified point.
-- @param x destination x
-- @param y destination y
Screen.line = function(x,y) _norns.screen_line(x,y) end

--- draw line to specified point relative to current position.
-- @param x relative destination x
-- @param y relative destination y
Screen.line_rel = function(x, y) _norns.screen_line_rel(x, y) end

--- draw arc.
-- @param x circle center x
-- @param y circle center y
-- @param r radius
-- @param angle1 start angle
-- @param angle2 end angle
Screen.arc = function(x, y, r, angle1, angle2) _norns.screen_arc(x, y, r, angle1, angle2) end

--- draw circle.
-- @param x origin x
-- @param y origin y
-- @param r radius
Screen.circle = function(x, y, r) _norns.screen_circle(x, y, r) end

--- draw rectangle.
-- @param x x position
-- @param y y position
-- @param w width
-- @param h height
Screen.rect = function(x, y, w, h) _norns.screen_rect(x, y, w, h) end

--- draw curve (cubic Bézier spline).
-- @param x1 destination x
-- @param y1 destination y
-- @param x2 handle 1 x
-- @param y2 handle 1 y
-- @param x3 handle 2 x
-- @param y3 handle 2 y
Screen.curve = function(x1, y1, x2, y2, x3, y3) _norns.screen_curve(x1, y1, x2, y2, x3, y3) end

--- draw curve (cubic Bézier spline) relative coordinates.
-- @param x1 relative destination x
-- @param y1 relative destination y
-- @param x2 handle 1 x
-- @param y2 handle 1 y
-- @param x3 handle 2 x
-- @param y3 handle 2 y
Screen.curve_rel = function(x1, y1, x2, y2, x3, y3) _norns.screen_curve_rel(x1, y1, x2, y2, x3, y3) end

--- close current path.
Screen.close = function() _norns.screen_close() end

--- stroke current path.
-- uses currently selected color.
Screen.stroke = function() _norns.screen_stroke() end

--- fill current path.
-- uses currently selected color.
Screen.fill = function() _norns.screen_fill() end

--- draw text (left aligned).
-- uses currently selected font.
-- @tparam string str : text to write
Screen.text = function(str) _norns.screen_text(str) end

--- draw text, right aligned.
-- uses currently selected font
-- @tparam string str : text to write.
Screen.text_right = function(str) _norns.screen_text_right(str) end

--- draw text, center aligned.
-- uses currently selected font.
-- @tparam string str : text to write
Screen.text_center = function(str) _norns.screen_text_center(str) end

--- select font face.
-- @param index font face (see list)
--
-- 1 04B_03 (norns default)
--
-- 2 ALEPH
--
-- 3 Roboto Thin
--
-- 4 Roboto Light
--
-- 5 Roboto Regular
--
-- 6 Roboto Medium
--
-- 7 Roboto Bold
--
-- 8 Roboto Black
--
-- 9 Roboto Thin Italic
--
-- 10 Roboto Light Italic
--
-- 11 Roboto Italic
--
-- 12 Roboto Medium Italic
--
-- 13 Roboto Bold Italic
--
-- 14 Roboto Black Italic
Screen.font_face = function(index) _norns.screen_font_face(index) end

--- set font size.
-- @param size in pixel height.
Screen.font_size = function(size) _norns.screen_font_size(size) end

--- draw single pixel (requires integer x/y, fill afterwards).
-- @param x position
-- @param y position
Screen.pixel = function(x, y)
  _norns.screen_rect(x, y, 1, 1)
end


_norns.screen_text_right = function(str)
  local x, y = _norns.screen_extents(str)
  _norns.screen_move_rel(-x, 0)
  _norns.screen_text(str)
end

_norns.screen_text_center = function(str)
  local x, y = _norns.screen_extents(str)
  _norns.screen_move_rel(-x/2, 0)
  _norns.screen_text(str)
end

_norns.screen_circle = function(x, y, r)
  _norns.screen_arc(x, y, r, 0, math.pi*2)
end

--- display png.
-- @param filename
-- @param x x position
-- @param y y position
Screen.display_png = function(filename,x,y) _norns.screen_display_png(filename,x,y) end


return Screen
