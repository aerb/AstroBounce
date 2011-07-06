require "xmlParser"
require "AnAL"

function add(a, b, coll)
    characterState = true
end

function persist(a, b, coll)

end

function rem(a, b, coll)

end

function result(a, b, coll)

end

function love.load()
  world = love.physics.newWorld(-1000, -1000, 2000, 2000) 
  world:setGravity(0, 0) 
  world:setMeter(64)
  world:setCallbacks(add, persist, rem, result)
  
  -- Create animation.  
  clockDiv = 0
  slowDown = 0
  
  planets = {}
  
  inFronts = {} 
  behinds = {}
  
  flakes = {}
  flakeImage = love.graphics.newImage("data/images/flake.png")
  
  backGround={}
  backGround.image = love.graphics.newImage("data/images/space.png")
  backGround.scaleW =  650/backGround.image:getHeight()
  backGround.scaleH =  650/backGround.image:getHeight()
  
  characterBody = love.physics.newBody(world, 400, 400, 15, 0)
  characterHead = love.physics.newBody(world, 425, 425, 1, 0)
  characterHead:setLinearDamping(7)
  characterShape = love.physics.newCircleShape(characterBody, 0, 0, 15)
  characterHeadShape = love.physics.newCircleShape(characterHead, 0, 0, 15)
  
  characterJoint = love.physics.newDistanceJoint( characterBody, characterHead, characterBody:getX(), characterBody:getY(), characterHead:getX(), characterHead:getY() )
  characterShape:setFriction(0.4)
  characterState = false
  characterImage = love.graphics.newImage("data/images/character.png")
  characterImageJump = love.graphics.newImage("data/images/cjump.png")
  characterHeadImage = love.graphics.newImage("data/images/head.png")
  
  

  local pXml = collectFromFile("/Users/adamerb/Documents/2010Fall/Games/levels.xml")
  print(pXml[1])
  t=pXml[2]
  for i,v in ipairs(t) do 
        if v["label"] == "planet" then
            local x=v["xarg"]["posx"]
            local y=v["xarg"]["posy"]
            local radius=v["xarg"]["radius"]
            print(x,y,radius)
            p={}
            p.body = love.physics.newBody(world, x, y, 0, 0)
            p.shape = love.physics.newCircleShape(p.body, 0, 0, radius)
            p.shape:setFriction(1)
            p.image = love.graphics.newImage("data/images/astroid.png")
            p.scale = radius/p.image:getHeight()*2.39
            p.orientation = 0 
            table.insert(planets,p)            
        elseif v["label"] == "infront" then
            for i2,v2 in ipairs(v) do
                if v2["label"] == "planet"then
                    fg={}
                    fg.x=v2["xarg"]["posx"]*2
                    fg.y=v2["xarg"]["posy"]*2
                    fg.r=v2["xarg"]["radius"]*4
                    fg.i0 = love.graphics.newImage("data/images/t0.png")
                    fg.i1 = love.graphics.newImage("data/images/t1.png")
                    fg.i2 = love.graphics.newImage("data/images/t2.png")
                    fg.i3 = love.graphics.newImage("data/images/t3.png")
                    fg.i4 = love.graphics.newImage("data/images/t4.png")                                        
                    fg.scale = fg.r/fg.i0:getHeight()
                    fg.spinSpeed = math.random(-5,5)/1000
                    fg.orientation = 0
                    table.insert(inFronts,fg)
                end
            end     
        elseif v["label"] == "behind" then
            for i2,v2 in ipairs(v) do
                if v2["label"] == "planet"then
                    fg={}
                    fg.x=v2["xarg"]["posx"]/2
                    fg.y=v2["xarg"]["posy"]/2
                    fg.r=v2["xarg"]["radius"]/2
                    fg.image = love.graphics.newImage("data/images/t2.png")
                    fg.scale = fg.r/fg.image:getHeight()
                    fg.spinSpeed = math.random(-5,5)/1000
                    fg.orientation = 0
                    table.insert(behinds,fg)
                end
            end     
        end
  end
  
  --initial graphics setup 
  love.graphics.setBackgroundColor(0, 0, 20)
  love.graphics.setMode(650, 650, false, true, 0)
end

function getDistance(body1,body2)
    local xdiff = (v.body:getX()-characterBody:getX())
    local ydiff = (v.body:getY()-characterBody:getY())
    return math.sqrt(xdiff^2+ydiff^2)
end

function getClosest()
    min = nil
    for i,v in ipairs(planets) do 
        local xdiff = math.abs(v.body:getX()-characterBody:getX())
        local ydiff = math.abs(v.body:getY()-characterBody:getY())
        local rad = math.sqrt(xdiff^2+ydiff^2)
        rad = rad - v.shape:getRadius()
        if min == nil then
            min = v
            minRad = rad
        elseif rad < minRad then
            minRad = rad
            min = v
        end
    end
    return min
end

function calcTangent(body1,body2)
     local xdiff = body2:getX() - body1:getX()
     local ydiff = body2:getY() - body1:getY()
     
     theta = math.atan(ydiff/xdiff)
     
     if xdiff >= 0 then
         theta = theta + math.pi
     end

     local xW = math.cos(theta - math.pi/2)
     local yW = math.sin(theta - math.pi/2)
     return xW,yW
end

function calcAngle(body1,body2)
    local xdiff = body2:getX() - body1:getX()
    local ydiff = body2:getY() - body1:getY()
    local theta = math.atan((ydiff/xdiff)) + math.pi/2
    if body2:getX() - body1:getX() < 0 then
        theta = theta + math.pi
    end
    return theta
end

function calcNormalForce(body1,body2,f)
    local xdiff = body2:getX() - body1:getX()
    local ydiff = body2:getY() - body1:getY()
    local theta = math.atan(math.abs(ydiff/xdiff))
    local xC = math.cos(theta)
    local yC = math.sin(theta)

    if(ydiff < 0) then
        yC = -1*yC
    end

    if(xdiff < 0) then
        xC = -1*xC
    end
    return -xC*f,-yC*f
end

function calcGravityForce(body1,body2,f)
    local xdiff = body2:getX() - body1:getX()
    local ydiff = body2:getY() - body1:getY()
    local rad = math.sqrt(xdiff^2+ydiff^2)
    local theta = math.atan(math.abs(ydiff/xdiff))

    local force = f/(rad) 
    local fX = force*math.cos(theta)
    local fY = force*math.sin(theta)

    if(ydiff < 0) then
        fY = -1*fY
    end

    if(xdiff < 0) then
        fX = -1*fX
    end

    if fX >= 300 then
        fX = 300
    elseif fX <= -300 then
        fX = -300
    end
    if fY >= 300 then
        fY = 300
    elseif fY <= -300 then
        fY = -300
    end
    return fX,fY
end

function getSpeed(body)
    x,y = body:getLinearVelocity()
    return math.sqrt(x^2 + y^2)
end

function love.update(dt)
      
    
  if clockDiv >= slowDown then
      clockDiv = 0
      local c = getClosest()    
      x,y = calcGravityForce(characterBody,c.body, c.shape:getRadius()*500)
      characterBody:applyForce(x,y)
      x,y = calcGravityForce(characterHead,c.body, c.shape:getRadius()*100)
      characterHead:applyForce(-x,-y)
  
      x,y = characterBody:getLinearVelocity()
      local xt,yt = calcTangent(characterBody,c.body)
      if love.keyboard.isDown("right") then --press the right arrow key to push the ball to the right
          if characterState == true then
              characterBody:setLinearVelocity(xt*150,yt*150)
              if getSpeed(characterBody) < 200 then 
                  characterBody:setLinearVelocity(xt*15+x,yt*15+y) 
                  characterHead:setLinearVelocity(xt*60+x,yt*60+y)
               end
          else
              characterBody:applyForce(xt*30,yt*30)      
          end
      elseif love.keyboard.isDown("left") then --press the left arrow key to push the ball to the left
          if characterState == true then
              characterBody:setLinearVelocity(xt*-150,yt*-150)      
              if getSpeed(characterBody) < 200 then 
                  characterBody:setLinearVelocity(xt*-15+x,yt*-15+y)
                  characterHead:setLinearVelocity(xt*-60+x,yt*-60+y)  
              end
          else
            characterBody:applyForce(xt*-30,yt*-30)       
          end
      end
      if love.keyboard.isDown("up") then --press the up arrow key to set the ball in the air
          if characterState == true then
              characterState = false
              xg,yg = calcNormalForce(characterBody,c.body,1000)
              characterBody:setLinearVelocity(xg+ x,yg+ y)
          end
      end
      if love.keyboard.isDown("down") then --press the up arrow key to set the ball in the air
          if slowDown ~= 2 then
              slowDown = 2
          else
              slowDown = 0
          end
      end
      if love.mouse.isDown("l") then
          xt, yt = love.mouse.getPosition( )
          x,y = characterBody:getPosition()
          bulletBody = love.physics.newBody(world, x+xt, y+yt, 15, 0)
          bulletShape = love.physics.newCircleShape(characterBody, 0, 0, 10)
      end
      
      world:update(dt*0.8)   
  else
      clockDiv = clockDiv + 1
  end
  
end


function love.draw()
  love.graphics.draw(backGround.image,0,0,0,backGround.scaleW,backGround.scaleH,0,0)
  love.graphics.setColor(50,50,50)   
  for i,v in ipairs(behinds) do 
      v.orientation = v.spinSpeed + v.orientation
      love.graphics.draw(v.image, v.x-characterBody:getX()/2+650/2, v.y-characterBody:getY()/2+650/2,v.orientation,v.scale,v.scale,v.image:getWidth()/2,v.image:getHeight()/2)
  end
  love.graphics.setColor(255, 255, 255)
  love.graphics.circle("line", 650/2, 650/2, characterShape:getRadius(), 100)
  love.graphics.circle("line", characterHead:getX() - characterBody:getX() + 650/2, characterHead:getY() - characterBody:getY() + 650/2, characterHeadShape:getRadius(), 100)

  local c = getClosest()
   x,y = calcTangent(characterBody,c.body)
  local cOrientGround = math.atan(y/x)  
  if characterBody:getY() - c.body:getY() > 0 then
    cOrientGround = cOrientGround + math.pi
  end
  
  love.graphics.line(0+650/2,0+650/2,x*100+650/2,y*100+650/2)
  local cOrient = calcAngle(characterBody,characterHead)
  if characterState == true then
      love.graphics.draw(characterImage, 650/2 , 650/2,cOrientGround,0.2,0.2,characterImage:getWidth()/2,characterImage:getHeight()/2)
  else
      love.graphics.draw(characterImageJump, 650/2 , 650/2,cOrient,0.2,0.2,characterImage:getWidth()/2,characterImage:getHeight()/2)
  end
  love.graphics.draw(characterHeadImage,characterHead:getX() - characterBody:getX() + 650/2, characterHead:getY() - characterBody:getY() + 650/2,cOrient,0.2,0.2,characterImage:getWidth()/2,characterImage:getHeight()/2)

  
  
  for i,v in ipairs(planets) do 
      love.graphics.draw(v.image, v.body:getX() - characterBody:getX() + 650/2,v.body:getY()-characterBody:getY() + 650/2, v.shape:getRadius(),v.scale,v.scale,v.image:getWidth()/2,v.image:getHeight()/2)
  end
  
  for i,v in ipairs(flakes) do 
   love.graphics.draw(flakeImage, v.x - characterBody:getX() + 650/2, v.y - characterBody:getY() + 650/2,0,1,1,0,0)
  end
  
  if bulletBody ~= nil then
      x,y = bulletBody:getPosition()
      love.graphics.circle( "fill", x+650/2, y+650/2, 10, 10 )
  end
  
  for i,v in ipairs(inFronts) do 
      v.orientation = v.spinSpeed + v.orientation
      local xPlace = v.x-characterBody:getX()*2+650/2
      local yPlace = v.y-characterBody:getY()*2+650/2
      local dist = math.sqrt((xPlace-650/2)^2 + (yPlace-650/2)^2)
      local radLimit = v.r/2
      if dist > radLimit*1.2 then
          love.graphics.draw(v.i0, xPlace , yPlace, v.orientation,v.scale,v.scale,v.i0:getWidth()/2,v.i0:getWidth()/2)
      elseif dist > radLimit*1.10 then
          love.graphics.draw(v.i1, xPlace , yPlace, v.orientation,v.scale,v.scale,v.i0:getWidth()/2,v.i0:getWidth()/2)
      elseif dist > radLimit then
          love.graphics.draw(v.i2, xPlace , yPlace, v.orientation,v.scale,v.scale,v.i0:getWidth()/2,v.i0:getWidth()/2)
      elseif dist > radLimit*0.9 then
          love.graphics.draw(v.i3, xPlace , yPlace, v.orientation,v.scale,v.scale,v.i0:getWidth()/2,v.i0:getWidth()/2)
      else
          love.graphics.draw(v.i4, xPlace , yPlace, v.orientation,v.scale,v.scale,v.i0:getWidth()/2,v.i0:getWidth()/2)
      end
  end
end