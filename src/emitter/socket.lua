local socket = require'socket'
assert(socket._VERSION:match('^LuaSocket 3%.'))

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
  local self = {}
  local sock
  self.connect = function(port,ip)
    ip = ip or 'localhost'
    if not isip(ip) then
      error('invalid ip')
    end
    if isipv6(ip) then
      sock = socket.tcp6()
    else
      sock = socket.tcp()
    end
  end
  self.write = function() end
  self.fin = function() end
  self.destroy = function() end
  self.pause = function() end
  self.resume = function() end
  self.settimeout = function() end
  self.setkeepalive = function() end
  self.setnodelay = function() end
  self.on = function() end
  self.once = function() end
  self.addlistener = function() end
  self.removelistener = function() end
  return self
end

return {
  new = new
}
