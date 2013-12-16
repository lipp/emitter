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
  local closing = false
  local watcher = {}
  self.connect = function(port,ip)
    ip = ip or 'localhost'
    if not isip(ip) then
      error('invalid ip')
    end
    if sock and closing then
      self:once('close',function(self)
          self:_connect(port,ip)
        end)
      
    elseif not connecting then
      self:_connect(port,ip)
    end
  end
  
  self._connect = function(port,ip)
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
      self:emit('connect',self)
    elseif err == 'timeout' or err == 'Operation already in progress' then
      watcher.connect = ev.IO.new(function(loop,io)
          io:stop(loop)
          self:emit('connect',self)
        end,sock:getfd(),ev.WRITE)
      watcher.connect:start(loop)
    else
      self:emit('error',err)
    end
  end
  self.write = function() end
  self.fin = function() end
  self.destroy = function() end
  self.pause = function() end
  self.resume = function() end
  self.set_timeout = function() end
  self.set_keepalive = function() end
  self.set_nodelay = function() end
  return self
end

return {
  new = new
}
