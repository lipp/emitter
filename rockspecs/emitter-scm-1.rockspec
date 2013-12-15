package = "emitter"
version = "scm-1"

source = {
  url = "git://github.com/lipp/emitter.git",
}

description = {
  summary = "Node.js inspired integration of lua-ev and sockets,etc",
  homepage = "http://github.com/lipp/emitter",
  license = "MIT/X11",
  detailed = ""
}

dependencies = {
  "lua >= 5.1",
  "luasocket",
  "lua-ev",
}

build = {
  type = 'none',
  install = {
    lua = {
      ['emitter'] = 'src/emitter.lua',
      ['emitter.socket'] = 'src/emitter/socket.lua',
    }
  }
}

