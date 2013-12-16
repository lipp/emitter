local ev = require'ev'

local tinsert = table.insert
local tremove = table.remove

local create_next_tick = function(loop)
  if ev.Idle then
    local on_idle
    local idle_io = ev.Idle.new(
      function(loop,idle_io)
        idle_io:stop(loop)
        on_idle()
      end)
    return function(f)
      on_idle = f
      idle_io:start(loop)
    end
  else
    local eps = 2^-40
    local once
    local on_timeout
    local timer_io = ev.Timer.new(
      function(loop,timer_io)
        once = true
        timer_io:stop(loop)
        on_timeout()
      end,eps)
    return function(f)
      if once then
        timer_io:again(loop)
      else
        timer_io:start(loop)
      end
    end
  end
end

local new = function()
  local self = {}
  local listeners = {}
  local max_listeners = 10
  
  self.add_listener = function(_,event,listener)
    listeners[event] = listeners[event] or {}
    if #listeners[event] > max_listeners then
      error('max_listeners limit reached for event '..event)
    end
    tinsert(listeners[event],listener)
    return self
  end
  
  self.on = self.add_listener
  
  self.remove_listener = function(_,event,oldlistener)
    if listeners[event] then
      for i,listener in ipairs(listeners[event]) do
        if listener == oldlistener then
          tremove(listeners[event],i)
          return self
        end
      end
    end
    return self
  end
  
  local remove_all_listeners_for_event = function(event)
    for _,listener in ipairs(listeners[event] or {}) do
      self:remove_listener(listener)
    end
  end
  
  self.remove_all_listeners = function(_,event)
    if event then
      remove_all_listeners_for_event(event)
    else
      for event in pairs(listeners) do
        remove_all_listeners_for_event(event)
      end
    end
    return self
  end
  
  self.once = function(_,event,listener)
    local remove
    remove = function()
      self:remove_listener(event,remove)
      self:remove_listener(event,listener)
    end
    self:add_listener(event,listener)
    self:add_listener(event,remove)
    return self
  end
  
  self.emit = function(_,event,...)
    for _,listener in ipairs(listeners[event] or {}) do
      local ok,err = pcall(listener,...)
      if not ok then
        print('error in listener',err)
      end
    end
    return self
  end
  
  return self
end

return {
  new = new,
  next_tick = create_next_tick(ev.Loop.default),
}
