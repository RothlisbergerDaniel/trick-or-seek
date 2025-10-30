love.graphics.setDefaultFilter("nearest", "nearest", 1)

push = require "lib.push" -- resolution manager
collisions = require "lib.collisions" -- collision detection library
pprint = require "lib.pprint" -- printer for tables and the like
neighborhood = require "lib.neighborhood"
scanner = require "lib.scanner"
kids = require "lib.kids"


local step = 1.0/60 -- fixed timestep
local acc = 0       -- accumulator
local ioTimer = 0
local ioMax = 1/15
local scanTimer = 0
local scannerCode = ""
mouse = {x=0, y=0, dX=0, dY=0, down} -- mouse table for use with resolution scaling
windowScale = {x=1, y=1}
screenScale = {x=640,y=360}
co = {x=1,y=1} -- center offset for neighborhood grid
co.x = (screenScale.x * 0.5) - ((neighborhood.dimensions.x+1) * neighborhood.dimensions.ox * 0.5)
co.y = (screenScale.y * 0.5) - ((neighborhood.dimensions.y+1) * neighborhood.dimensions.oy * 0.5)
fs =  not false -- fullscreen toggle
master = false -- whether this instance of the game is the "master" instance
mPos = {x=0,y=0,dx=0,dy=0}
mD = {x=0,y=0,dx=0,dy=0}
cGrid = {{0,0,0,0},{0,0,0,0},{0,0,0,0},{0,0,0,0}} -- fallback because without this it crashes the game for some reason???

hCandy = 0 -- hider candy
rCandy = 15 -- required candy

pD = {x=16,y=16} -- player hitbox dimensions

childCount = 10 -- number of children to spawn

function love.load()
  local wW, wH = love.window.getDesktopDimensions()
  if fs then
    push:setupScreen(640, 360, wW, wH, {fullscreen = fs})
  else
    push:setupScreen(640, 360, 640, 360, {fullscreen = fs})
  end
  
  --local t = pprint.pformat(windowScale)
  --print(t)
  
  math.randomseed(os.time())
  c = {math.random(),math.random(),math.random()}
  love.mouse.setVisible(false)
  
  reset()
  --cGrid = loadData().g
  --pprint(cGrid)
  
end

function reset()
  
  hCandy = 0
  
  mD.x, mD.y = love.mouse.getPosition()
  
  neighborhood.load()
  kids.generate(childCount)
  
  if master then step = 1.0/60 else step = 1.0/15 end
  
end

function love.update(dt)
  windowScale.x = love.graphics.getWidth() / 768; windowScale.y = love.graphics.getHeight() / 432
  getMouseData(windowScale)
  
  acc = acc + dt
  ioTimer = ioTimer + dt
  scanTimer = scanTimer + dt
  if scanTimer > 0.1 or string.len(scannerCode) > 2 or string.len(scannerCode) == 2 then --if the scan takes too long, or goes over the max, or hits the max:
    if string.len(scannerCode) == 2 then --if it's the right length, execute the scan option
      doScan(scannerCode, true)
      scannerCode = ""
    end
    if scanTimer > 0.1 and string.len(scannerCode) > 2 then
      doScan(scannerCode, false)
      scannerCode = "" -- reset the code regardless
    end
  end
  while ioTimer > ioMax do
    ioTimer = ioTimer - ioMax
    
    if master then
      mD.dx = (mouse.x - mD.x)*((1/15)/step); mD.dy = (mouse.y - mD.y)*((1/15)/step)
      mD.x = mouse.x; mD.y = mouse.y
      
      local t = {
        x = mouse.x,
        y = mouse.y,
        dx = mD.dx or 0,
        dy = mD.dy or 0,
        g = neighborhood.candyGrid,
        k = kids.kids,
      }
      saveData(t)
      
    else
      local d = loadData() or {x=0,y=0}
      mPos.x, mPos.y, mPos.dx, mPos.dx = d.x, d.y, d.dx, d.dy
      cGrid = d.g
      kids.kids = d.k
      --pprint(cGrid)
      
    end
    
  end
    
  while acc >= step do
    acc = acc - step
    
    neighborhood.update(step)
    kids.update(step)
    --[[if not master then
      mPos.x = mPos.x + (mPos.dx or 0) * step
      mPos.y = mPos.y + (mPos.dy or 0) * step
    end]]
    
    
    
  end
  
  
  
end

function love.draw()
  push:start()
    
    love.graphics.clear(0.05, 0.051, 0.3)
    love.graphics.setColor(1,1,1)
    
    neighborhood.draw()
    
    kids.draw()
    
    love.graphics.setColor(1,1,1)
    if master then
      love.graphics.rectangle("line", mouse.x-16, mouse.y-16, 32, 32)
      love.graphics.rectangle("fill", mouse.x-8, mouse.y-8, 16, 16)
      --love.graphics.print(tostring(kids.checkInters({x=mouse.x,y=mouse.y})), 20, 40)
    else
      love.graphics.rectangle("fill", mPos.x-16, mPos.y-16, 32, 32)
    end
    
    
    
    neighborhood.drawRooves()
    
  push:finish()
end

function getMouseData(scale)
  local mx,my = love.mouse.getPosition()
  mouse.dX = mx - mouse.x; mouse.dY = my - mouse.y -- get mouse deltas
  
  mouse.x, mouse.y = mx, my
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

function doScan(code, valid)
  if valid then
    print(code.." - Valid")
    return code
  else
    if string.len(code) > 2 then
      print(code.." - Invalid - Scan exceeds maximum length")
    else
      print(code.." - Invalid - Scan timeout")
    end
  end
  
  return false
end


function love.keypressed(key, scanCode, isrepeat)
  if key == "escape" then -- closes game
    love.event.quit()
    
  end
  if key == "`" then -- swap master and slave instance
    master = not master
    if master then
      reset()
      local t = {
        x = mouse.x,
        y = mouse.y,
        g = neighborhood.candyGrid,
        k = kids.kids,
      }
      saveData(t)
    end
    
  end
  if key == "backspace" then
    local wW, wH = love.window.getDesktopDimensions()
    push:setupScreen(640, 360, 640, 360, {fullscreen = false})
    push:setupScreen(640, 360, wW, wH, {fullscreen = true})
    
  end
  
  
  if string.find("abcdefghijklmnopqrstuvwxyz1234567890", tostring(key)) then
    
    scannerCode = scannerCode..tostring(key)
    scanTimer = 0
    
  end
  
  
  
end