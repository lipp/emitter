local ev = require'ev'

local create_process_next_tick = function(loop)
  if ev.Idle then
    local on_idle
    local idle_io = ev.Idle.new(
      function(loop,idle_io)
        on_idle()
        idle_io:stop(loop)
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
        on_timeout()
        timer_io:stop(loop)
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
  loop = loop or ev.Loop.default
  local process_next_tick = create_process_next_tick(loop)
  local self = {}
  local listeners = {}
  self.addlistener = function(_,event,listener)
    listeners[event] = listeners[event] or {}
    listeners[event][listener] = true
  end
  self.on = self.addlistener
  self.removelistener = function(_,event,listener)
    if listeners[event] then
      listeners[event][listener] = nil
      if not next(listeners) then
        listeners[event] = nil
      end
    end
  end
  self.once = function(self,event,listener)
    local remove
    remove = function()
      self:removelistener(event,listener)
      self:removelistener(event,remove)
    end
    self:addlistener(event,listener)
    self:addlistener(event,remove)
  end
  local fire = function(event,...)
    for listener in pairs(listeners[event] or {}) do
      local ok,err = pcall(listener,...)
      if not ok then
        print('error in listener',err)
      end
    end
  end
  self.emit = function(_,event,...)
    local args = {...}
    process_next_tick(function()
        fire(event,unpack(args))
      end)
  end
  return self
end

return {
  new = new
}