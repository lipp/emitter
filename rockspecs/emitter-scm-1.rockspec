package = "emitter"
version = "scm-1"

source = {
  url = "git://github.com/lipp/emitter.git",
}

description = {
  summary = "Lua equivalent to node.js EventEmitter",
  homepage = "http://github.com/lipp/emitter",
  license = "MIT/X11",
  detailed = ""
}

dependencies = {
  "lua >= 5.1",
}

build = {
  type = 'none',
  install = {
    lua = {
      ['emitter'] = 'src/emitter.lua',
    }
  }
}

