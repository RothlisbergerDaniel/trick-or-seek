love.graphics.setDefaultFilter("nearest", "nearest", 1)

push = require "lib.push" -- resolution manager
collisions = require "lib.collisions" -- collision detection library
pprint = require "lib.pprint" -- printer for tables and the like


local step = 1.0/60 -- fixed timestep
local acc = 0       -- accumulator
local ioTimer = 0
mouse = {x, y, down} -- mouse table for use with resolution scaling
windowScale = {x=1, y=1}
fs = false -- fullscreen toggle
master = false -- whether this instance of the game is the "master" instance
mPos = {x=0,y=0}

function love.load()
  local wW, wH = love.window.getDesktopDimensions()
  if fs then
    push:setupScreen(768, 432, wW, wH, {fullscreen = fs})
  else
    push:setupScreen(768, 432, 768, 432, {fullscreen = fs})
  end
  
  --local t = pprint.pformat(windowScale)
  --print(t)
  
  math.randomseed(os.time())
  c = {math.random(),math.random(),math.random()}
  
end

function love.update(dt)
  windowScale.x = love.graphics.getWidth() / 768; windowScale.y = love.graphics.getHeight() / 432
  getMouseData(windowScale)
  
  acc = acc + dt
  ioTimer = ioTimer + dt
  while ioTimer > 0.1 do
    ioTimer = ioTimer - 0.1
    
    if master then
      local t = {
        x = mouse.x,
        y = mouse.y,
      }
      saveData(t)
      
    else
      local d = loadData()
      mPos.x, mPos.y = d.x, d.y
      
    end
    
  end
    
  while acc >= step do
    acc = acc - step
    
    
    
    
    
  end
  
  
  
end

function love.draw()
  push:start()
    
    love.graphics.clear(c[1], c[2], c[3])
    love.graphics.setColor(1,1,1)
    if master then
      love.graphics.circle("fill", mouse.x, mouse.y, 20)
    else
      love.graphics.circle("fill", mPos.x, mPos.y, 20)
    end
  
  push:finish()
end

function getMouseData(scale)
  mouse.x, mouse.y = love.mouse.getPosition()
  mouse.down = love.mouse.isDown(1)
  
  mouse.x, mouse.y = push:toGame(mouse.x, mouse.y)
  if not mouse.x then mouse.x = -100 end
  if not mouse.y then mouse.y = -100 end
  --mouse.x = mouse.x / scale.x; mouse.y = mouse.y / scale.y
  
  
  
  --mouse.tile = {x,y}
  --mouse.tile.x, mouse.tile.y = map:convertPixelToTile(mouse.x, mouse.y)
  --mouse.tile.x = math.ceil(mouse.tile.x); mouse.tile.y = math.ceil(mouse.tile.y)
  
end

function saveData(data)
  local f = io.open("save-data.lua", "w")
  
  local t = pprint.pformat(data)
  
  if f then
    f:write("return "..t)
    f:close()
  else
    error("Failed to open save file!")
  end
  
  
end

function loadData()
  local d = dofile "save-data.lua"
  --pprint(d)
  return d
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then -- closes game
    love.event.quit()
    
  end
  if key == "q" then -- swap master and slave instance
    master = not master
    
  end
  
  
end