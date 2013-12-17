local tinsert = table.insert
local tremove = table.remove

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
    listeners[event] = nil
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
  
  local emit_listeners = {}
  
  self.emit = function(_,event,...)
    local listeners = listeners[event]
    if listeners then
      for i,listener in ipairs(listeners) do
        emit_listeners[i] = listener
      end
      for i=1,#listeners do
        local ok,err = pcall(emit_listeners[i],...)
        if not ok then
          print('error in listener',err)
        end
      end
    end
    return self
  end
  
  return self
end

return {
  new = new,
}
