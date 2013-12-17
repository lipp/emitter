setloop('ev')

describe('The emitter module',function()
    local emitter = require'emitter'
    it('provides new method',function()
        assert.is_function(emitter.new)
      end)
    
    it('esock.new returns an object/table',function()
        assert.is_table(emitter.new())
      end)
    
    describe('with an emitter instance',function()
        local i
        before_each(function()
            i = emitter.new()
          end)
        
        local expected_methods = {
          'add_listener',
          'on',
          'once',
          'remove_listener',
          'emit',
        }
        
        for _,method in ipairs(expected_methods) do
          it('i.'..method..' is function',function()
              assert.is_function(i[method])
            end)
        end
        
        it('i.add_listener and i.on are the same method',function()
            assert.is_equal(i.add_listener,i.on)
          end)
        
        it('i.on callback gets called with correct arguments',function(done)
            i:on('foo',async(function(a,b)
                  assert.is_equal(a,'test')
                  assert.is_equal(b,123)
                  done()
              end))
            i:emit('foo','test',123)
          end)
        
        it('i.on callback gets called once for each emit',function(done)
            local count = 0
            i:on('foo',async(function()
                  count = count + 1
                  if count == 2 then
                    done()
                  end
              end))
            i:emit('foo')
            i:emit('foo')
          end)
        
        it('once is really called once',function(done)
            local count = 0
            i:once('bar',async(function()
                  count = count + 1
              end))
            local b = 0
            i:on('bar',async(function()
                  b = b + 1
                  if b == 2 then
                    assert.is_equal(count,1)
                    done()
                  end
              end))
            i:emit('bar',1)
            i:emit('bar',2)
          end)
      end)
  end)
