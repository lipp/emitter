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
        
        it('emitter.next_tick works',function(done)
            emitter.next_tick(function()
                i:emit('foo','test',123)
              end)
            i:on('foo',async(function(a,b)
                  assert.is_equal(a,'test')
                  assert.is_equal(b,123)
                  done()
              end))
          end)
        
        
        it('the call context for nexttick and on callbacks is different',function(done)
            local s = 1
            emitter.next_tick(function()
                i:emit('foo')
              end)
            i:on('foo',async(function()
                  assert.is_equal(s,2)
                  done()
              end))
            s = 2
          end)
        
        
        
      end)
  end)
