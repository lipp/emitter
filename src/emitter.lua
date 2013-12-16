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

local new = function(loop)
  local self = {}
  local listeners = {}
  
  self.addlistener = function(_,event,listener)
    listeners[event] = listeners[event] or {}
    tinsert(listeners[event],listener)
  end
  
  self.on = self.addlistener
  
  self.removelistener = function(_,event,oldlistener)
    if listeners[event] then
      for i,listener in ipairs(listeners[event]) do
        if listener == oldlistener then
          tremove(listeners[event],i)
          return
        end
      end
    end
  end
  
  self.once = function(self,event,listener)
    local remove
    remove = function()
      self:removelistener(event,remove)
      self:removelistener(event,listener)
    end
    self:addlistener(event,listener)
    self:addlistener(event,remove)
  end
  
  self.emit = function(_,event,...)
    for _,listener in ipairs(listeners[event] or {}) do
      local ok,err = pcall(listener,...)
      if not ok then
        print('error in listener',err)
      end
    end
  end
  
  return self
end

return {
  new = new,
  nexttick = create_next_tick(ev.Loop.default),
}
