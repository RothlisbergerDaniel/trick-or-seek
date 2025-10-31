love.graphics.setDefaultFilter("nearest", "nearest", 1)

push = require "lib.push" -- resolution manager
collisions = require "lib.collisions" -- collision detection library
pprint = require "lib.pprint" -- printer for tables and the like
neighborhood = require "lib.neighborhood"
--scanner = require "lib.scanner"
kids = require "lib.kids"


local step = 1.0/60 -- fixed timestep
local acc = 0       -- accumulator
local ioTimer = 0
local ioMax = 1/10
local scanTimer = 0
local scannerCode = ""
mouse = {x=0, y=0, dX=0, dY=0, down} -- mouse table for use with resolution scaling
windowScale = {x=1, y=1}
screenScale = {x=640,y=360}
co = {x=1,y=1} -- center offset for neighborhood grid
co.x = (screenScale.x * 0.5) - ((neighborhood.dimensions.x+1) * neighborhood.dimensions.ox * 0.5)
co.y = (screenScale.y * 0.5) - ((neighborhood.dimensions.y+1) * neighborhood.dimensions.oy * 0.5)
fs = not false -- fullscreen toggle
master = false -- whether this instance of the game is the "master" instance
mPos = {x=0,y=0,dx=0,dy=0}
mD = {x=0,y=0,dx=0,dy=0}
cGrid = {{0,0,0,0},{0,0,0,0},{0,0,0,0},{0,0,0,0}} -- fallback because without this it crashes the game for some reason???

hCandy = 0 -- hider candy
rCandy = 5 -- required candy
hOutfit = 1 -- hider outfit
hDir = 1

pD = {x=4,y=4} -- player hitbox dimensions

childCount = 15 -- number of children to spawn

gameState = "start" -- "start", "setup", "countdown", "game", "hwin", "swin", 
gsTimer = 0 -- time before game starts
hTarget = {x=1,y=1}

scanDelay = 0
maxScanDelay = 10

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
  gameState = "start"
  
  local t = {
    x = mouse.x,
    y = mouse.y,
    dx = mD.dx or 0,
    dy = mD.dy or 0,
    g = neighborhood.candyGrid,
    k = kids.kids,
    c = hCandy,
    o = hOutfit,
    dir = hDir,
    state = gameState
  }
  saveData(t)
  
  loadSprites()
  --cGrid = loadData().g
  --pprint(cGrid)
  
end

function loadSprites()
  spritesheets = {
    kid1 = love.graphics.newImage("assets/kid1.png"),
    kid2 = love.graphics.newImage("assets/kid2.png"),
    kid3 = love.graphics.newImage("assets/kid3.png"),
    kid4 = love.graphics.newImage("assets/kid4.png"),
    kid5 = love.graphics.newImage("assets/kid5.png"),
    countdown = love.graphics.newImage("assets/countdown.png"),
    base = love.graphics.newImage("assets/base.png"),
    roof = love.graphics.newImage("assets/roof.png"),
    streets = love.graphics.newImage("assets/streets.png"),
    candy = love.graphics.newImage("assets/candy.png"),
    itembox = love.graphics.newImage("assets/itembox.png"),
    scanner = love.graphics.newImage("assets/scanner.png"),
    ghost = love.graphics.newImage("assets/ghost.png"),
    title = love.graphics.newImage("assets/title.png"),
    hwin = love.graphics.newImage("assets/hwin.png"),
    swin = love.graphics.newImage("assets/swin.png"),
    
  }
  
  kidsprites = {
    newAnimation(spritesheets.kid1, 32, 32, 0, false),
    newAnimation(spritesheets.kid2, 32, 32, 0, false),
    newAnimation(spritesheets.kid3, 32, 32, 0, false),
    newAnimation(spritesheets.kid4, 32, 32, 0, false),
    newAnimation(spritesheets.kid5, 32, 32, 0, false),
  }
  countdown = newAnimation(spritesheets.countdown, 48, 48, 0, false)
  streets = newAnimation(spritesheets.streets, 359, 359, 0, false)
  base = newAnimation(spritesheets.base, 48, 48, 0, false)
  roof = newAnimation(spritesheets.roof, 48, 48, 0, false)
  candy = newAnimation(spritesheets.candy, 48, 48, 0, false)
  itembox = newAnimation(spritesheets.itembox, 48, 48, 0, false)
  scanner = newAnimation(spritesheets.scanner, 48, 48, 0, false)
  ghost = newAnimation(spritesheets.ghost, 32, 32, 0, false)
  title = newAnimation(spritesheets.title, 320, 180, 0, false)
  hwin = newAnimation(spritesheets.hwin, 320, 180, 0, false)
  swin = newAnimation(spritesheets.swin, 320, 180, 0, false)
  
  
  
end

function reset()
  
  hCandy = 0
  
  mD.x, mD.y = love.mouse.getPosition()
  
  neighborhood.load()
  kids.generate(childCount)
  hOutfit = math.random(1,5)
  hDir = 1
  
  if master then step = 1.0/60 else step = ioMax end
  
end

function love.update(dt)
  windowScale.x = love.graphics.getWidth() / 768; windowScale.y = love.graphics.getHeight() / 432
  if gameState == "game" or gameState == "setup" then
    getMouseData(windowScale)
  end
  if gameState == "setup" then
    neighborhood.checkPlayerStartPos(dt)
  end
  if gameState == "hwin" or gameState == "swin" then
    if gsTimer > 0 and master then
      gsTimer = gsTimer - dt
    end
    if gsTimer <= 0 then
      gameState = "start"
      print("startmenu")
    end
  end
  
  acc = acc + dt
  ioTimer = ioTimer + dt
  scanTimer = scanTimer + dt
  if scanDelay > 0 then scanDelay = scanDelay - dt; if scanDelay < 0 then scanDelay = 0 end end
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
        c = hCandy,
        o = hOutfit,
        dir = hDir,
        state = gameState
      }
      saveData(t)
      
    else
      local d = loadData() or {x=0,y=0}
      mPos.x, mPos.y, mPos.dx, mPos.dx = d.x, d.y, d.dx, d.dy
      --if math.sign(d.dx) ~= 0 then hDir = math.sign(d.dx) end
      cGrid = d.g
      kids.kids = d.k
      hCandy = d.c or 0
      hOutfit = d.o or 1
      hDir = d.dir or 1
      gameState = d.state or gameState
      --pprint(cGrid)
      
    end
    
  end
    
  while acc >= step do
    acc = acc - step
    
    if gameState == "game" then
      neighborhood.update(step)
    end
    if gameState == "game" or gameState == "hwin" or gameState == "swin" then
      kids.update(step)
    end
    --[[if not master then
      mPos.x = mPos.x + (mPos.dx or 0) * step
      mPos.y = mPos.y + (mPos.dy or 0) * step
    end]]
    
    
    
  end
  
  
  
end

function love.draw()
  push:start()
    
    love.graphics.clear(0.2, 0.176, 0.302)
    love.graphics.setColor(1,1,1)
    --love.graphics.rectangle("fill",145,5,10,10)
    
    neighborhood.draw()
    
    if gameState == "game" or gameState == "hwin" or gameState == "swin" then kids.draw() end
    
    love.graphics.setColor(1,1,1)
    if gameState == "game" or gameState == "hwin" or gameState == "swin" then
      if master then
        --love.graphics.rectangle("line", mouse.x-16, mouse.y-16, 32, 32)
        --love.graphics.rectangle("fill", mouse.x-(pD.x*0.5), mouse.y-(pD.y*0.5), pD.x, pD.y)
        --love.graphics.print(tostring(kids.checkInters({x=mouse.x,y=mouse.y})), 20, 40)
        
        drawAnimationFrame(ghost, 1, mouse.x, mouse.y, hDir, 0, 1, 1)
      else
        if gameState == "game" then
          drawAnimationFrame(kidsprites[hOutfit], 3, mPos.x, mPos.y, hDir, 0, 1, 1)
        else
          drawAnimationFrame(ghost, 1, mPos.x, mPos.y, hDir, 0, 1, 1)
        end
        --love.graphics.rectangle("fill", mPos.x-16, mPos.y-16, 32, 32)
      end
    end
    if master and gameState == "setup" then drawAnimationFrame(ghost, 1, mouse.x, mouse.y, hDir, 0, 1, 1) end
    
    neighborhood.drawRooves()
    
    love.graphics.setColor(1,1,1)
    if gameState == "game" then love.graphics.print("Candy: "..hCandy.."/"..rCandy, 20, 20) end
    if gameState == "setup" and master then
      if gsTimer < 3 then
        drawAnimationFrame(countdown, math.ceil(gsTimer), 320, 180, 1, 0, 1, 1)
      end
    end
    if gameState == "start" then drawAnimationFrame(title, 1, 320, 120, 1, 0, 1, 1); love.graphics.print("Scan the Game Start barcode to begin!", 200, 345) end
    if gameState == "hwin" then drawAnimationFrame(hwin, 1, 320, 120, 1, 0, 1, 1) end
    if gameState == "swin" then drawAnimationFrame(swin, 1, 320, 120, 1, 0, 1, 1) end
    
  push:finish()
end

function getMouseData(scale)
  local mx,my = love.mouse.getPosition()
  mx,my = push:toGame(mx,my)
  mouse.dX = mx - mouse.x; mouse.dY = my - mouse.y -- get mouse deltas
  --print(mouse.dX)
  if math.abs(mouse.dX) > 0.33 then
    hDir = math.sign(mouse.dX)
  end
  mx,my = push:toReal(mx,my)
  
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
    
    if code == "gs" then
      if gameState == "start" or gameState == "hwin" or gameState == "swin" then
        gameState = "setup"
        hTarget = {x=math.random(1,4),y=math.random(1,4)}
        gsTimer = 3
        
        master = true
        if master then
          local t = {
            x = mouse.x,
            y = mouse.y,
            g = neighborhood.candyGrid,
            k = kids.kids,
          }
          saveData(t)
        end
      end
    elseif scanDelay <= 0 then
      
      local y,x = string.find("abcdefghijklmnopqrstuvwxyz", string.sub(code, 1, 1)), tonumber(string.sub(code, 2, 2))
      --print(x.." "..y)
      neighborhood.checkScanHit({x=x,y=y}) -- check if player is at that house
      scanDelay = maxScanDelay
      
    end
    
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

function startGame()
  local d = neighborhood.dimensions
  
  local x,y=(hTarget.x*d.ox)+co.x, (hTarget.y*d.oy)+co.y+(d.sy*0.7)
  x,y = push:toReal(x,y)
  love.mouse.setPosition(x,y)
  getMouseData(windowScale)
  reset()
  
  gameState = "game"
  
  
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
        dx = mD.dx or 0,
        dy = mD.dy or 0,
        g = neighborhood.candyGrid,
        k = kids.kids,
        c = hCandy,
        o = hOutfit,
        dir = hDir,
        state = gameState
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

function newAnimation(image, width, height, duration, loop)
  local anim = {}
  anim.spriteSheet = image
  anim.quads = {}
  anim.size = {x = width, y = height}
  
  for y= 0, image:getHeight() - height, height do
    for x = 0, image:getWidth() - width, width do
      table.insert(anim.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
    end
  end
  
  anim.duration = duration or 1 -- set animation duration in seconds; default is 1s
  anim.currentTime = 0 -- set starting time for looped animations
  anim.doLoop = loop
  anim.finished = false
  
  return anim
end

function updateAnimation(anim, dt)
  anim.currentTime = anim.currentTime + dt
  if anim.currentTime >= anim.duration then
    if anim.doLoop then
      anim.currentTime = anim.currentTime - anim.duration
    else
      anim.currentTime = anim.duration - 0.00001 -- subtract a tiny amount so we don't go over the limit
      anim.finished = true
    end
  else
    anim.finished = false
  end
end

function drawAnimation(anim, x, y, dir) -- draw arbitrary animation frame based on internal time; good for looped animations
  local frame = math.floor(anim.currentTime / anim.duration * #anim.quads) + 1
  love.graphics.draw(anim.spriteSheet, anim.quads[frame], x or 0, y or 0, 0, dir or 1, 1, anim.size.x / 2, anim.size.y / 2)
end

function drawAnimationFrame(anim, frame, x, y, dir, r, sX, sY) -- draw specific animation frame; good for finer control or animation states
  love.graphics.draw(anim.spriteSheet, anim.quads[frame], x or 0, y or 0, r or 0, (dir or 1) * (sX or 1), 1 * (sY or 1), anim.size.x / 2, anim.size.y / 2)
end

function math.sign(n) return n > 0 and 1 or n < 0 and -1 or 0 end -- get the sign of a number