setloop('ev')

describe('The emitter.socket module',function()
    local esock = require'emitter.socket'
    it('provides new method',function()
        assert.is_function(esock.new)
      end)
    
    it('esock.new returns an object/table',function()
        assert.is_table(esock.new())
      end)
    
    describe('with an emitter.socket instance',function()
        local i
        before_each(function()
            i = esock.new()
          end)
        
        local expected_methods = {
          'connect',
          'write',
          'fin',
          'destroy',
          'pause',
          'resume',
          'settimeout',
          'setnodelay',
          'setkeepalive',
          'on',
          'once',
          'addlistener',
          'removelistener',
        }
        
        for _,method in ipairs(expected_methods) do
          it('i.'..method..' is function',function()
              assert.is_function(i[method])
            end)
        end
        
        
      end)
  end)
