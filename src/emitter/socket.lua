local socket = require'socket'
assert(socket._VERSION:match('^LuaSocket 3%.'))
local emitter = require'emitter'
local ev = require'ev'

local isip = function(ip)
  local addrinfo,err = socket.dns.getaddrinfo(ip)
  if err then
    return false
  end
  return true
end

local isipv6 = function(ip)
  local addrinfo,err = socket.dns.getaddrinfo(ip)
  if addrinfo then
    assert(#addrinfo > 0)
    if addrinfo[1].family == 'inet6' then
      return true
    end
  end
  return false
end

local isipv4 = function(ip)
  return isip(ip) and not isipv6(ip)
end

local new = function()
  local self = emitter.new()
  local sock
  local loop = ev.Loop.default
  local connecting = false
  local connected = false
  local closing = false
  local watchers = {}
  
  local on_error = function(err)
    self:emit('error',err)
    self:emit('close')
    self:destroy()
  end
  
  local read_io = function()
    assert(sock)
    return ev.IO.new(function()
        local data,err,part = sock:receive(8192)
        if err then
          on_error(err)
        else
          self:emit('data',data or part)
        end
      end,sock:getfd(),ev.READ)
  end
  
  local pending
  local pos
  
  local write_io = function()
    assert(sock)
    return ev.IO.new(function(loop,io)
        local sent,err,so_far = sock:send(pending,pos)
        if not sent and err ~= 'timeout' then
          if err ~= 'closed' then
            self:emit('error',err)
          end
          self:emit('close')
          self:destroy()
        elseif sent then
          pos = nil
          pending = nil
          io:stop(loop)
          self:emit('_drain')
          self:emit('drain')
        else
          pos = so_far + 1
        end
      end,sock:getfd(),ev.WRITE)
  end
  
  local on_connect = function()
    connecting = false
    connected = true
    watchers.read = read_io()
    watchers.write = write_io()
    self:resume()
    self:emit('connect',self)
  end
  
  self.connect = function(_,port,ip)
    ip = ip or '127.0.0.1'
    if not isip(ip) then
      on_error(err)
    end
    if sock and closing then
      self:once('close',function(self)
          self:_connect(port,ip)
        end)
      
    elseif not connecting then
      self:_connect(port,ip)
    end
  end
  
  self._connect = function(_,port,ip)
    assert(not sock)
    if isipv6(ip) then
      sock = socket.tcp6()
    else
      sock = socket.tcp()
    end
    sock:settimeout(0)
    connecting = true
    closing = false
    local ok,err = sock:connect(ip,port)
    if ok or err == 'already connected' then
      on_connect()
    elseif err == 'timeout' or err == 'Operation already in progress' then
      watchers.connect = ev.IO.new(function(loop,io)
          local ok,err = sock:connect(ip,port)
          if ok or err == 'already connected' then
            io:stop(loop)
            watchers.connect = nil
            on_connect()
          else
            on_error(err)
          end
        end,sock:getfd(),ev.WRITE)
      watchers.connect:start(loop)
    else
      on_error(err)
    end
  end
  
  self.write = function(_,data)
    if pending then
      pending = pending..data
    else
      pending = data
      if connecting then
        self:once('connect',function()
            watchers.write:start(loop)
          end)
      elseif connected then
        watchers.write:start(loop)
      else
        self:emit('error',err)
        self:emit('close')
        self:destroy()
      end
    end
    return self
  end
  
  self.fin = function(_,data)
    if pending or data then
      if data then
        self:write(data)
      end
      self:once('_drain',function()
          sock:shutdown('send')
        end)
    else
      sock:shutdown('send')
    end
    return self
  end
  
  self.destroy = function()
    for _,watcher in pairs(watchers) do
      watcher:stop(loop)
    end
    if sock then
      sock:close()
      sock = nil
    end
  end
  
  self.pause = function()
    watchers.read:stop(loop)
  end
  
  self.resume = function()
    watchers.read:start(loop)
  end
  
  self.set_timeout = function() end
  self.set_keepalive = function() end
  self.set_nodelay = function(_,enable)
    if connecting then
      self:once('connect',function()
          sock:setoption('tcp-nodelay',enable)
        end)
    elseif connected then
      sock:setoption('tcp-nodelay',enable)
    else
      self:emit('error','socket closed')
    end
    return self
  end
  return self
end

return {
  new = new
}
