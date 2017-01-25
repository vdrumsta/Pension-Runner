local composer = require ("composer")
local scene = composer.newScene()
function scene:create(event)
    local group = self.view
    ----------------------------------------------------------------------------------------
    --
    -- main.lua
    --
    -----------------------------------------------------------------------------------------

    -- phyisics declaration
    local physics = require( "physics" )
    physics.start()
    physics.setGravity( 0, 1 )
    -- physics.setDrawMode("hybrid") -- check out my cool hitboxes

    -- particle declaration
    local particleDesigner = require( "particleDesigner" )

    -- some variables declaration
    local fuelUpgrade = composer.getVariable("setFuelUpgrade")  
    local defenseUpgrade = composer.getVariable("setDefenseUpgrade")   
    local accelerationUpgrade = composer.getVariable("setAccelerationUpgrade") 
    local handlingUpgrade = composer.getVariable("setHandlingUpgrade") 
    
    local minCarSpeed = 1.5
    local carSpeed = minCarSpeed
    local OGSpeed = carSpeed
    local boost = carSpeed + 10
    local isRoundOver = false
    local playerHasControl = true
    local laneWidth = 68
    local gravelWidth = 52
    local sideWhiteLaneWidth = 4
    local laneWhiteLaneWidth = 2

    local fuel = 100 + (fuelUpgrade * 50)
    local fuelAdded = 50
    local maxFuel = fuel
    local burstedTirePenalty = 1 -- lower is worse
    local burstedTireSwaying = 1
    local acceleration = 0.1 / (6 - accelerationUpgrade)
    local decceleration = 0.3
    local coneSlowDown = 0.3
    local horizontalAcceleration = 2 + handlingUpgrade
    local turningSpeed = 100            -- higher = slower
    local additionalRotation = 0        -- this is used when tires get bursted. The car tilts by this additional angle
    local gravelSlow = 0.98
    local maxBloodPool = 10 -- max amount of blood the tire can accumulate 
    local leftTireBloodPool = 0
    local rightTireBloodPool = 0

    -- background
    local background1 = display.newImage("background.png")
    background1.x = display.contentWidth  / 2
    background1.y = display.contentHeight / 2
    group:insert(background1)


    --BACKGROUND CANDY SCROLL----------------------------------------------------------------------
    local spawnedDecals = {}
        
    function spawnDecal ( decalFileName, xPosition, yPosition ) -- e.g. "ob2.png", 50, 100
        local indexToPlaceIn = #spawnedDecals + 1
        spawnedDecals[indexToPlaceIn] = display.newImage( decalFileName )
        -- if it's a blood stain then it rotates it to match the car rotation
        if decalFileName == "blood-stain1.png" then 
            spawnedDecals[indexToPlaceIn].rotation = car.rotation
            spawnedDecals[indexToPlaceIn].anchorY = 0.7
            spawnedDecals[indexToPlaceIn].obstacleName = decalFileName
        end
        spawnedDecals[indexToPlaceIn].x = xPosition
        spawnedDecals[indexToPlaceIn].y = yPosition
        
        createEventForMovement( spawnedDecals[indexToPlaceIn] )
        group:insert(spawnedDecals[indexToPlaceIn])
    end

    local laneDashes = {}

    function moveLaneDashes ( self, event )
        if self.y > display.contentHeight + 60 then                 -- when it goes bellow screen it places it 80 pixels above the dash that was in front
            self.y = laneDashes[self.i][self.prevj].y - 80
        else
            if isRoundOver == false then
                self.y = self.y + carSpeed
            end
        end
    end

    function createEventForLaneDashMovement(self)
        self.enterFrame = moveLaneDashes
        Runtime:addEventListener("enterFrame", self)
    end

    for i = 1, 2 do
        laneDashes[i] = {}
        for j = 1, 8 do
            laneDashes[i][j] = display.newImage("lane-dash.png")
            laneDashes[i][j].x = 124 + (i - 1) * 70                 -- seperates lanes 2 and 3 if i = 1, seperates lanes 3 and 4 if i = 2
            laneDashes[i][j].y = (-80 + (j - 1) * 80)               -- places the dashes with 80 pixels between their centers
            laneDashes[i][j].i = i                                  -- this is so that I can retrieve it's index in moveLaneDashes function
            laneDashes[i][j].prevj = j + 1                          -- this is so that I can retrieve the index of the dash that's in front
            if laneDashes[i][j].prevj == 9 then                     -- ofcourse, life is not perfect so we must turn the value of prevj to 1 if dash thats in front index is 8 (8 + 1 = 9)
                laneDashes[i][j].prevj = 1
            end
            createEventForLaneDashMovement(laneDashes[i][j])        -- create an event for each instance
            group:insert(laneDashes[i][j])
        end
    end
    ---END BACKGROUND CANDY SCROLL-----------------------------------------------------------------

    ---Tire Trail----------------------------------------------------------------------------
    tireTrails = {}
    function leaveTireTrail (xPosition, yPosition, color) -- 
        local indexToPlaceIn = #tireTrails + 1
        fillColor = color or {0, 1, 1}
        tireTrails[indexToPlaceIn] = display.newRect(xPosition, yPosition, 5, 5)
        tireTrails[indexToPlaceIn]:setFillColor( unpack(fillColor) )
        createEventForMovement(tireTrails[#tireTrails])
        group:insert(tireTrails[indexToPlaceIn])
    end
    -----------------------------------------------------------------------------------------

    ---Movement------------------------------------------------------------------------------
    car = display.newImage("Car1.png")
    car.myName = "car"
    car.x = 160
    car.y = 350
    car.anchorY = 0.7
    group:insert(car)

    speedY = 50

    local leftPressed = false
    local rightPressed = false
    local downPressed = false
    local upPressed = false

    local slowMotionActivated = false
    local heartBeatSound = audio.loadSound ( "heart-beat.mp3" )

    local slowMotionFrameCounter = 0

    function slowMotion (event)
        if slowMotionActivated == false then
            local heartBeatChannel = audio.play( heartBeatSound )
        end
        slowMotionActivated = true
        carSpeed = 1
        physics.setTimeStep( 1/1000 )
        slowMotionFrameCounter = slowMotionFrameCounter + 1
        if (slowMotionFrameCounter > 30) then
            carSpeed = OGSpeed
            physics.setTimeStep( 1/60 )
            slowMotionActivated = false
            slowMotionFrameCounter = 0
            Runtime:removeEventListener( "enterFrame", slowMotion )
        end
    end

    -- prevent the rotation overlapping (which would cause it to turn after a key is released
    local rightTurnRotation = false
    local function rightTurnRotationStarted( self )
        rightTurnRotation = true
    end
    local function rightTurnRotationCompleted( self )
        rightTurnRotation = false
    end

    local leftTurnRotation = false
    local function leftTurnRotationStarted( self )
        leftTurnRotation = true
    end
    local function leftTurnRotationCompleted( self )
        leftTurnRotation = false
    end

    local straightTurnRotation = false
    local function straightTurnRotationStarted( self )
        straightTurnRotation = true
    end
    local function straightTurnRotationCompleted( self )
        straightTurnRotation = false
    end

    local function updateMovement()
        -- Acceleration
        if upPressed and playerHasControl == true and fuel > 0 then
            carSpeed = carSpeed + acceleration * burstedTirePenalty
            fuel = fuel - 0.1
        end
        
        -- Left turn
        if (leftPressed and not rightPressed) and playerHasControl == true then
            if rightTurnRotation == false then
                transition.to( car, {rotation=-45, time=turningSpeed, onStart=rightTurnRotationStarted, onComplete=rightTurnRotationCompleted} )
            end
            car.x = car.x - horizontalAcceleration
        end
        
        -- Right turn
        if (rightPressed and not leftPressed) and playerHasControl == true then
            if leftTurnRotation == false then
                transition.to( car, {rotation=45, time=turningSpeed, onStart=leftTurnRotationStarted, onComplete=leftTurnRotationCompleted} )
            end
            car.x = car.x + horizontalAcceleration
        end
        
        -- Right and Left pressed at the same time
        if rightPressed and leftPressed and playerHasControl == true then
            if straightTurnRotation == false then
                transition.to( car, {rotation = 0 + additionalRotation, time=turningSpeed, onStart=straightTurnRotationStarted, onComplete=straightTurnRotationCompleted} )
            end
        end
        
        -- Not turning
        if not rightPressed and not leftPressed and playerHasControl == true then
            if straightTurnRotation == false then
                transition.to( car, {rotation = 0 + additionalRotation, time=turningSpeed, onStart=straightTurnRotationStarted, onComplete=straightTurnRotationCompleted} )
            end
        end
        
        -- Brake
        if (downPressed) and playerHasControl == true and not (carSpeed < minCarSpeed) then
            carSpeed = carSpeed - (decceleration * burstedTirePenalty)
        end
        
        -- Increases speed up to minCarSpeed if the speed is bellow minCarSpeed and theres fuel left
        if carSpeed < minCarSpeed and fuel > 0 then
            carSpeed = carSpeed + 0.1
        -- If no fuel left then sets it to 0 when it's bellow 0
        elseif carSpeed < 0 and isRoundOver == true then
            carSpeed = 0
        end
        
        -- left boundary wall
        if car.x < (0 + car.width / 2) then
            car.x = 0 + car.width / 2
        end
        
        -- right boundary wall
        if car.x > (display.contentWidth - car.width / 2) then
            car.x = display.contentWidth - car.width / 2
        end
        
        -- slowing down the car on left gravel lane
        if (car.x - car.width / 2) < gravelWidth then
            carSpeed = carSpeed * gravelSlow
            
            car.leftTirePositionX = car.x - car.width / 2 + 3
            car.leftTirePositionY = car.y + (car.height - car.height * car.anchorY)
            
            car.rightTirePositionX = car.x + car.width / 2 - 5
            car.rightTirePositionY = car.y + (car.height - car.height * car.anchorY)
            
            if car.leftTirePositionX < gravelWidth then
                leaveTireTrail(car.leftTirePositionX, car.leftTirePositionY, {0.55, 0.3, 0.22, 0.2})
            end
            
            if car.rightTirePositionX < gravelWidth then
                leaveTireTrail(car.rightTirePositionX, car.rightTirePositionY, {0.55, 0.3, 0.22, 0.2})
            end
        end
        
        -- slowing down the car on right gravel lane
        if (car.x + car.width / 2) > (display.contentWidth - gravelWidth) then
            carSpeed = carSpeed * gravelSlow
            
            car.leftTirePositionX = car.x - car.width / 2 + 3
            car.leftTirePositionY = car.y + (car.height - car.height * car.anchorY)
            
            car.rightTirePositionX = car.x + car.width / 2 - 3
            car.rightTirePositionY = car.y + (car.height - car.height * car.anchorY)
            
            if car.leftTirePositionX > (display.contentWidth - gravelWidth) then
                leaveTireTrail(car.leftTirePositionX, car.leftTirePositionY, {0.55, 0.3, 0.22, 0.2})
            end
            
            if car.rightTirePositionX > (display.contentWidth - gravelWidth) then
                leaveTireTrail(car.rightTirePositionX, car.rightTirePositionY, {0.55, 0.3, 0.22, 0.2})
            end
        end
        
        -- leaving a left blood trail
        if leftTireBloodPool > 0 then
            car.leftTirePositionX = car.x - car.width / 2 + 3
            car.leftTirePositionY = car.y + (car.height - car.height * car.anchorY)
            leaveTireTrail(car.leftTirePositionX, car.leftTirePositionY, {1, 0, 0, (1 * leftTireBloodPool / maxBloodPool)})
            leftTireBloodPool = leftTireBloodPool - 0.1
        end
        
        -- leaving a left blood trail
        if rightTireBloodPool > 0 then
            car.rightTirePositionX = car.x + car.width / 2 - 3
            car.rightTirePositionY = car.y + (car.height - car.height * car.anchorY)
            leaveTireTrail(car.rightTirePositionX, car.rightTirePositionY, {1, 0, 0, (1 * rightTireBloodPool / maxBloodPool)})
            rightTireBloodPool = rightTireBloodPool - 0.1
        end
        
        -- reduces fuel
        if isRoundOver == false and fuel > 0 then
            fuel = fuel - 0.05 * carSpeed / maxSpeed / 0.5
        end
        
        -- slow the car down if outta fuel
        if isRoundOver == false and fuel <= 0 then
            carSpeed = carSpeed - 0.01
            
            -- loosing by running out of fuel. gotta up your personal finance game brotha
            if carSpeed <= 0 and fuel <= 0 then
                roundOver()
            end
        end
        
        -- swaying from bursted left tire
        if isRoundOver == false and leftTireBursted == true then
            car.x = car.x - burstedTireSwaying * (1 - handlingUpgrade / (3 + 1))


        end
        
        -- swaying from bursted left tire
        if isRoundOver == false and rightTireBursted == true then
            car.x = car.x + burstedTireSwaying * (1 - handlingUpgrade / (3 + 1))
        end
        
        car:toFront()   -- brings car to the top layer
    end

    local function touchScreen(event)
        if event.phase == "began" then
            transition.to(car, {time=speedY, x=event.x, y= y})
        end
        
    end

    local function onKeyEvent(event)
        if(event.keyName == "left") then
            if(event.phase == "down") then
                leftPressed = true
            end
            if(event.phase == "up") then
                leftPressed = false
            end
        end
        if(event.keyName == "right") then
            if(event.phase == "down") then
                rightPressed = true
            end
            if(event.phase == "up") then
                rightPressed = false
            end
        end
        if(event.keyName == "down") then
            if(event.phase == "down") then
                downPressed = true
            end
            if(event.phase == "up") then
                downPressed = false
            end
        end
         if(event.keyName == "up") then
            if(event.phase == "down") then
                upPressed = true
            end
            if(event.phase == "up") then
                upPressed = false
            end
        end
    end

    Runtime:addEventListener( "key", onKeyEvent )

    ---GrannyMovement-----------------------------------------------------------------------------


    ---End of Movement----------------------------------------------------------------------------


    -----OBSTACLE SPAWNING v0.7------------------------------------------------------------
    -- some variables
    local rowSpeedSpacingDifficulty = 15 -- lower is easier

    -- a tile is  the space that's provided for a single standard obstacle. These are not collision dimensions
    tileWidth = 48 + 68 * carSpeed / 20
    tileHeight = 68

    -- positions where obstacles spawn
    local spawnPos = {} -- new array
    for i = 2, 4 do
        spawnPos[i] = (gravelWidth + sideWhiteLaneWidth + laneWidth / 2  + laneWidth * (i - 2) + laneWhiteLaneWidth * (i - 2))
    end
    spawnPos[1] = (gravelWidth / 2)
    spawnPos[5] = (display.contentWidth - gravelWidth / 2)

    -- 1 = traffic cone, 2 = ob2, 3 = ob3
    local obstacleNames = {} -- picture names (e.g. traffic-cone.png) are stored here
    obstacleNames[1] = "traffic-cone.png"
    obstacleNames[2] = "manHole"
    obstacleNames[3] = "ob3.png"
    obstacleNames[4] = "glass.png"
    obstacleNames[5] = "road-barrier.png"
    obstacleNames[6] = "contruction-site.png"
    obstacleNames[7] = "construction-sign.png"

    local goodItemNames = {}
    goodItemNames[1] = "granny" -- not specifying an image name, cause it's an animated items
    goodItemNames[2] = "jerry-can.png" -- this will be replaced with stuff like boost

    local sheetOptions =
    {
        width = 32,
        height = 32,
        numFrames = 3,
        sheetContentWidth=96,
        sheetContentHeight=32
    }
    local sparksSheetOptions = 
    {
        width = 35,
        height = 45,
        numFrames = 3,
        sheetContentWidth = 105,
        sheetContentHeight = 45
    }
    local manHoleSheetOptions =
    {
        width = 32,
        height = 32,
        numFrames = 2,
        sheetContentWidth=192,
        sheetContentHeight=32
    }

    local grannySheet = graphics.newImageSheet( "Granny.png", sheetOptions )
    -- local sparksSheet = graphics.newImageSheet( "Sparks1.png", sparksSheetOptions)
    local manHoleSheet = graphics.newImageSheet( "Man-Hole.png", manHoleSheetOptions)

    local sequenceData = {
        name = "Walk",
        start=1,
        count=3,
        time=800
    }
    local sparksSequenceData = {
        name = "Shoot",
        start = 1,
        count = 3,
        time = 800
    }
    local manHoleSequenceData = {
        name = "Reveal",
        start=1,
        count=2,
        time=800
    }

    local manHoleSheetOptions = graphics.newImageSheet( "Man-Hole.png", manHoleSheetOptions )
    local sparksSheetOptions = graphics.newImageSheet( "Sparks1.png", sparksSheetOptions )

    -- This is where the obstacles are held along with their x, y coordinates and speed
    local spawnedObstacles = {}
    local hoboSpawned = false

    function randomSpawnSystem(rows)
        local rowSpeedSpacing = carSpeed / rowSpeedSpacingDifficulty
        local currentSpawnPos = 2
        local obstaclesInRow = 0
        local currentRow = 0 -- goes up by 1 every 3 cycles
        local rowSpacing = 3 + rowSpeedSpacing
      
        for i=1,rows do
            for j=1,3 do
                local percentageForSafeTile = 50
                local percentageForGrannySpawn = 20
                local randomDisplacement = 50
          
                if math.random(1,100) > percentageForSafeTile and obstaclesInRow ~= 2 then -- obstacle tile
                    spawnObstacle(obstacleNames[math.random(1,5)], currentSpawnPos)
                    spawnedObstacles[#spawnedObstacles].y = (-10 - ((currentRow) * rowSpacing * tileHeight) + math.random(-(randomDisplacement), randomDisplacement)) - randomDisplacement
                    
                    obstaclesInRow = obstaclesInRow + 1
                elseif math.random(1,100) <= percentageForGrannySpawn then -- safe tile
                    local fuelPickUpSpawnChance = 5 -- percentage chance for fuel to spawn as opposed to a granny
                    local goodItemToSpawn = 1
                    if fuelPickUpSpawnChance > math.random(1,100) then
                        goodItemToSpawn = 2
                    end
                    
                    spawnObstacle(goodItemNames[goodItemToSpawn], currentSpawnPos)
                    spawnedObstacles[#spawnedObstacles].y = (-10 - ((currentRow) * rowSpacing * tileHeight) + math.random(-(randomDisplacement), randomDisplacement)) - randomDisplacement
                end
                
                -- if hoboSpawnPercentage == false and 100 >= math.random(1,100) then
                    -- local hoboLane = math.random(1,2)
                    -- if hoboLane == 2 then -- if lanes is set to 2 change it to 5 (we only want him to spawn on sideLanes
                        -- hoboLane = 5
                    -- end
                    
                    -- spawnObstacle("hobo.png", 1)
                    -- spawnedObstacles[#spawnedObstacles].y = (-10 - ((currentRow) * rowSpacing * tileHeight) + math.random(-(randomDisplacement), randomDisplacement)) - randomDisplacement
                -- end
                
                currentSpawnPos = currentSpawnPos + 1
                if currentSpawnPos == 5 then
                    currentSpawnPos = 2
                    obstaclesInRow = 0
                end
            end
            currentRow = currentRow + 1
        end
    end

    function zigzagSpawnSystem(rows)
        local rowSpeedSpacing = carSpeed / rowSpeedSpacingDifficulty
        local startingLane = math.random(2,4)
        local currentSpawnPos = startingLane
        local maxObstaclesToSpawn = 2 -- the max number if consecutive obstacles to spawn without providing a granny or a free space
        local side = 1                -- this is the number that will be added to currentSpawnPos each cycle and it will change between 1 and -1
        for i=1,rows do
            if currectSpawnPos == 3 and maxObstaclesToSpawn == 3 then
                maxObstaclesToSpawn = 2
            end
            
            -- pick the change for safe block/obstacle block. different conditions for different consecutive obstacles spawned where maxObstaclesToSpawn = 0 is 3 consecutive obstacles
            local percentageForSafeTile = 0 -- default chance
            if maxObstaclesToSpawn      == 2 then
                percentageForSafeTile  = percentageForSafeTile
            elseif maxObstaclesToSpawn  == 1 then
                percentageForSafeTile  = percentageForSafeTile
            elseif maxObstaclesToSpawn  == 0 then
                percentageForSafeTile  = 100
            end
            
            if math.random(1,100) > percentageForSafeTile then -- spawns obstacle
                spawnObstacle(obstacleNames[1], currentSpawnPos)
                spawnedObstacles[#spawnedObstacles].y = (-32 - ((i - 1) * tileHeight * (1 + rowSpeedSpacing))) -- overwrite y spawning position
                
            else -- safe block
                spawnObstacle(goodItemNames[1], currentSpawnPos)
                spawnedObstacles[#spawnedObstacles].y = (-32 - ((i - 1) * tileHeight * (1 + rowSpeedSpacing))) -- overwrite y spawning position
                
                maxObstaclesToSpawn = 3
            end
            
            -- change the direction of the obstacle lane spawning
            if currentSpawnPos == 4 then
                side = -1
            elseif currentSpawnPos == 2 then
                side = 1
            end
            -- change the lane on which the obstacle will spawn
            currentSpawnPos = currentSpawnPos + side
            
            maxObstaclesToSpawn = maxObstaclesToSpawn - 1
        end
    end

    function upsideDownLSpawnSystem(rows)
        local counter = rows
        local randomSide = (math.random(1,2) * 2) -- choose to start spawning on the left or the right (2 or 4 lane)
        while counter > 0 do -- repeats this loop rows amount of time
            spawnObstacle(obstacleNames[1], randomSide)
            spawnedObstacles[#spawnedObstacles].y = (-32 - ((rows - counter) * tileHeight)) -- overwrite y spawning position
            
            counter = counter - 1
        end
        
        local randomGrannySide = (math.random(1,2) * 2) -- choose to start spawning on the left or the right (2 or 4 lane)
        for i = 1, 2 do
            -- create grannys
            spawnObstacle(goodItemNames[1], randomGrannySide)
            spawnedObstacles[#spawnedObstacles].y = (-32 - ((rows + i - 1) * tileHeight)) -- overwrite y spawning position
            
            local side = 0
            if randomGrannySide == 4 then
                side = 3
            end
            
            -- create obstacles
            spawnObstacle(obstacleNames[2], randomGrannySide)
            spawnedObstacles[#spawnedObstacles].y = (-32 - ((rows + 2 - 1) * tileHeight)) -- overwrite y spawning position
            spawnedObstacles[#spawnedObstacles].x = spawnPos[randomGrannySide + i - side] -- opposite side of grannys 
            
        end
    end

    function heartBeatSpawnSystem(rows)
        local counter = rows
        local upwardLanes = 3
        local coneShapedLanes = 5
        local coneShapedStartX = 56
        local tunnelWidth = car.width + 100
        local tunnelShiftFrequency = 9 -- every x completes a sin cycle
        local currentHeight = -50
        local upwardLaneFinishedX = 0 -- x coordinates where upward lane finishes spawning obstacle it's last obstacle
        local tunnelLaneLeftX = 0 -- x coordinates of where the leftward obstacle spawns
        
        for i = 1, upwardLanes do -- initial obstacles leading upward
            currentHeight = currentHeight - tileHeight
            spawnObstacle(obstacleNames[5], 2)
            spawnedObstacles[#spawnedObstacles].x = 56 + spawnedObstacles[#spawnedObstacles].width / 2   -- 56 pixels from left is where the lanes begin
            spawnedObstacles[#spawnedObstacles].y = currentHeight
            
            spawnObstacle(obstacleNames[5], 4)
            spawnedObstacles[#spawnedObstacles].x = 264 - spawnedObstacles[#spawnedObstacles].width / 2  -- 264 pixels from left is where the lanes end
            spawnedObstacles[#spawnedObstacles].y = currentHeight
        end
        
        for i = 1, coneShapedLanes do -- obstacles leading into the tunnel
            currentHeight = currentHeight - tileHeight
            spawnObstacle(obstacleNames[1])
            upwardLaneFinishedX = coneShapedStartX + spawnedObstacles[#spawnedObstacles].width / 2 + (display.contentWidth / 2 - coneShapedStartX - tunnelWidth / 2 - spawnedObstacles[#spawnedObstacles].width / 2) / coneShapedLanes * i
            spawnedObstacles[#spawnedObstacles].x = upwardLaneFinishedX
            spawnedObstacles[#spawnedObstacles].y = currentHeight
            
            spawnObstacle(obstacleNames[1])
            spawnedObstacles[#spawnedObstacles].x = display.contentWidth - coneShapedStartX - spawnedObstacles[#spawnedObstacles].width / 2 - (display.contentWidth / 2 - coneShapedStartX - tunnelWidth / 2 - spawnedObstacles[#spawnedObstacles].width / 2) / coneShapedLanes * i
            spawnedObstacles[#spawnedObstacles].y = currentHeight
        end
        
        for i = 1, rows do -- tunnel shape
            currentHeight = currentHeight - tileHeight
            spawnObstacle(obstacleNames[1])
            tunnelLaneLeftX = upwardLaneFinishedX + math.sin(math.pi / tunnelShiftFrequency * i) * tunnelWidth / 2 -- adds the wavyness. -5 for some correctness
            spawnedObstacles[#spawnedObstacles].x = tunnelLaneLeftX
            spawnedObstacles[#spawnedObstacles].y = currentHeight
            tunnelLaneLeftX = tunnelLaneLeftX + spawnedObstacles[#spawnedObstacles].width / 2
            
            if 20 > math.random(1, 100) then
                spawnObstacle(goodItemNames[1])
                spawnedObstacles[#spawnedObstacles].x = tunnelLaneLeftX + spawnedObstacles[#spawnedObstacles].width + 25 -- + tunnelWidth / 2
                spawnedObstacles[#spawnedObstacles].y = currentHeight
            end
            
            spawnObstacle(obstacleNames[1])
            spawnedObstacles[#spawnedObstacles].x = upwardLaneFinishedX + tunnelWidth + math.sin(math.pi / tunnelShiftFrequency * i) * tunnelWidth / 2 - 5 -- adds the wavyness. -5 for some correctness
            spawnedObstacles[#spawnedObstacles].y = currentHeight
        end
    end

    function zebraSpawnSystem()
        spawnDecal( "zebra-lane.png", display.contentWidth / 2, -82 )
        
        for i = math.random(1, 5), 10 do -- spawns 5-10 grannies
            spawnObstacle(goodItemNames[1], math.random(2, 4))
            spawnedObstacles[#spawnedObstacles].y = spawnedObstacles[#spawnedObstacles].y + math.random(-40, 40)
            spawnedObstacles[#spawnedObstacles].x = spawnedObstacles[#spawnedObstacles].x - math.random(-40, 40)
            print(spawnedObstacles[#spawnedObstacles].y)
        end
    end

    function constructionSiteSpawnSystem()
        local rowSpeedSpacing = carSpeed / rowSpeedSpacingDifficulty
        local laneToSpawnIn = math.random(2,4)
        
        spawnObstacle( obstacleNames[7], laneToSpawnIn ) -- spawns the sign
        if laneToSpawnIn == 4 then
            spawnedObstacles[#spawnedObstacles].xScale = -1
        end
        spawnObstacle( obstacleNames[6], laneToSpawnIn ) -- spawns construction site
        
        local laneSpawnedIn = 0
        local spacing = 300 * (1 + rowSpeedSpacing)
        spawnedObstacles[#spawnedObstacles].y = spawnedObstacles[#spawnedObstacles].y - spacing
        for i = 1, 2 do
            local randomLane = math.random(2,4)
            while randomLane == laneSpawnedIn do
                randomLane = math.random(2,4)
            end
            laneSpawnedIn = randomLane
            
            spawnObstacle ( obstacleNames[1], randomLane )
            spawnedObstacles[#spawnedObstacles].y = spawnedObstacles[#spawnedObstacles].y - spacing / 2
        end
    end

    -- takes in the index of obstacleNames which it should spawn and the lane in which it should spawn the obstacle
    function spawnObstacle(obstacle, lane)
        local laneToPlaceIn = lane or 1
        local obstacleCollisionFilter = { categoryBits = 2, maskBits = 1 }
        local indexToPlaceIn = #spawnedObstacles + 1
        if obstacle == "granny" then
            spawnedObstacles[indexToPlaceIn] = display.newSprite( grannySheet, sequenceData )
            spawnedObstacles[indexToPlaceIn]:play()
            spawnedObstacles[indexToPlaceIn].dead = false
            if 1 == math.random(1,2) then
                spawnedObstacles[indexToPlaceIn].xScale = -1
            end
        elseif  obstacle == "manHole" then
            spawnedObstacles[indexToPlaceIn] = display.newSprite( manHoleSheetOptions, manHoleSequenceData )
            spawnedObstacles[indexToPlaceIn]:play()
        else
            spawnedObstacles[indexToPlaceIn] = display.newImage(obstacle)
        end
        spawnedObstacles[indexToPlaceIn].obstacleName = obstacle
        spawnedObstacles[indexToPlaceIn].x = spawnPos[laneToPlaceIn]
        spawnedObstacles[indexToPlaceIn].y = -82
        spawnedObstacles[indexToPlaceIn].speed = carSpeed
        spawnedObstacles[indexToPlaceIn].hasCollided = false
        createEventForMovement(spawnedObstacles[indexToPlaceIn])
        if obstacle == obstacleNames[1] then
            pentagonShape = { 13, 11, -12, 11, 0, -15, 0, 0 }
            physics.addBody( spawnedObstacles[indexToPlaceIn], "dynamic", {filter = obstacleCollisionFilter, shape = pentagonShape} )
        else
            physics.addBody( spawnedObstacles[indexToPlaceIn], "dynamic", {filter = obstacleCollisionFilter} )
        end
        if obstacle == obstacleNames[2] or obstacle == obstacleNames[3] or obstacle == obstacleNames[4] or obstacle == obstacleNames[6] then
            spawnedObstacles[indexToPlaceIn].isSensor = true -- doesnt physically get pushed when colliding with the car, but still produces collision event
        end
        spawnedObstacles[indexToPlaceIn].gravityScale = 0
        spawnedObstacles[indexToPlaceIn].isOffScreen = false
        group:insert(spawnedObstacles[indexToPlaceIn])
    end

    -- moves the obstacle carSpeed pixels down the y-axis
    function createEventForMovement(self)
        self.enterFrame = moveObstacle
        Runtime:addEventListener("enterFrame", self)
    end

    local spawnedGibs = {}
    gibsCollisionCollisionFilter = { categoryBits = 3, maskBits = 0 }

    function moveObstacle( self, event )
        self.speed = carSpeed
        
        if isRoundOver == true and (self.obstacleName == "granny" or self.obstacleName == "manHole") then -- stops animation if the round is over
            self:pause()
        end
        
        if self.obstacleName == obstacleNames[4] then -- glass collision done here
            car.upperLeftTirePositionX = car.x - car.width / 2
            car.upperLeftTirePositionY = car.y - (car.height * car.anchorY)
            
            car.upperRightTirePositionX = car.x + car.width / 2
            car.upperRightTirePositionY = car.y - (car.height * car.anchorY)
            
            car.lowerLeftTirePositionX = car.x - car.width / 2
            car.lowerLeftTirePositionY = car.y + (car.height * (1 - car.anchorY))
            
            car.lowerRightTirePositionX = car.x + car.width / 2
            car.lowerRightTirePositionY = car.y + (car.height - car.height * car.anchorY)
            
            -- check if upper left tire is on the glass obstacle
            if car.upperLeftTirePositionX < (self.x + self.width / 2) and car.upperLeftTirePositionX > (self.x - self.width / 2) and car.upperLeftTirePositionY < (self.y + self.height / 2) and car.upperLeftTirePositionY > (self.y - self.height / 2) then
                burstLeftTire()
            end
            
            -- check if upper right tire is on the glass obstacle
            if car.upperRightTirePositionX < (self.x + self.width / 2) and car.upperRightTirePositionX > (self.x - self.width / 2) and car.upperRightTirePositionY < (self.y + self.height / 2) and car.upperRightTirePositionY > (self.y - self.height / 2) then
                burstRightTire()
            end
            
            -- check if lower left tire is on the glass obstacle
            if car.lowerLeftTirePositionX < (self.x + self.width / 2) and car.lowerLeftTirePositionX > (self.x - self.width / 2) and car.lowerLeftTirePositionY < (self.y + self.height / 2) and car.lowerLeftTirePositionY > (self.y - self.height / 2) then
                burstLeftTire()
            end
            
            -- check if lower left tire is on the glass obstacle
            if car.lowerRightTirePositionX < (self.x + self.width / 2) and car.lowerRightTirePositionX > (self.x - self.width / 2) and car.lowerRightTirePositionY < (self.y + self.height / 2) and car.lowerRightTirePositionY > (self.y - self.height / 2) then
                burstRightTire()
            end
        elseif self.obstacleName == "blood-stain1.png" then
            car.upperLeftTirePositionX = car.x - car.width / 2
            car.upperLeftTirePositionY = car.y - (car.height * car.anchorY)
            
            car.upperRightTirePositionX = car.x + car.width / 2
            car.upperRightTirePositionY = car.y - (car.height * car.anchorY)
            
            car.lowerLeftTirePositionX = car.x - car.width / 2
            car.lowerLeftTirePositionY = car.y + (car.height * (1 - car.anchorY))
            
            car.lowerRightTirePositionX = car.x + car.width / 2
            car.lowerRightTirePositionY = car.y + (car.height - car.height * car.anchorY)
            
            -- check if upper left tire is on the blood splatter
            if car.upperLeftTirePositionX < (self.x + self.width / 2) and car.upperLeftTirePositionX > (self.x - self.width / 2) and car.upperLeftTirePositionY < (self.y + self.height / 2) and car.upperLeftTirePositionY > (self.y - self.height / 2) then
                if leftTireBloodPool <= maxBloodPool then
                    leftTireBloodPool = leftTireBloodPool + 0.1 * (1 + carSpeed / maxSpeed)
                end
            end
            
            -- check if upper right tire is on the blood splatter
            if car.upperRightTirePositionX < (self.x + self.width / 2) and car.upperRightTirePositionX > (self.x - self.width / 2) and car.upperRightTirePositionY < (self.y + self.height / 2) and car.upperRightTirePositionY > (self.y - self.height / 2) then
                if rightTireBloodPool <= maxBloodPool then
                    rightTireBloodPool = rightTireBloodPool + 0.1 * (1 + carSpeed / maxSpeed)
                end
            end
            
            -- check if lower left tire is on the blood splatter
            if car.lowerLeftTirePositionX < (self.x + self.width / 2) and car.lowerLeftTirePositionX > (self.x - self.width / 2) and car.lowerLeftTirePositionY < (self.y + self.height / 2) and car.lowerLeftTirePositionY > (self.y - self.height / 2) then
                if leftTireBloodPool <= maxBloodPool then
                    leftTireBloodPool = leftTireBloodPool + 0.1 * (1 + carSpeed / maxSpeed)
                end
            end
            
            -- check if lower right tire is on the blood splatter
            if car.lowerRightTirePositionX < (self.x + self.width / 2) and car.lowerRightTirePositionX > (self.x - self.width / 2) and car.lowerRightTirePositionY < (self.y + self.height / 2) and car.lowerRightTirePositionY > (self.y - self.height / 2) then
                if rightTireBloodPool <= maxBloodPool then
                    rightTireBloodPool = rightTireBloodPool + 0.1 * (1 + carSpeed / maxSpeed)
                end
            end
        elseif self.obstacleName == goodItemNames[1] and self.y > -(self.height) and isRoundOver == false then -- move granny
            if self.xScale == -1 then   -- if turned right
                self.x = (self.x + carSpeed / maxSpeed * 0.5)
            else                        -- if turned left
                self.x = (self.x - carSpeed / maxSpeed * 0.5)
            end
        end
        
        if  self.y > display.contentHeight + 32 then -- when the obstacle moves off screen, remove him
            self.isOffScreen = true
            self:removeSelf()
            Runtime:removeEventListener( "enterFrame", self )
            self = nil -- flush self
            self = -1 -- fill the gap in the table spawnedObstacles
            -- print(self.isOffScreen)
        else
            if isRoundOver == false then -- stops obstacle movement if the round is over
                self.y = (self.y + self.speed)
            end
        end
        
        if self ~= -1 and self.obstacleName == "granny" and self.dead == true then -- spawns gibs if the granny is dead
            if self.deathChosen == nil then
                local percentageForGibExplosion = 50 -- % to explode into gibs
                local aRandomPercentage = math.random(1, 100)
                if carSpeed > 5 and aRandomPercentage <= percentageForGibExplosion then
                    spawnGibs(self)
                    physics.removeBody( self )
                    self:removeSelf()
                    Runtime:removeEventListener( "enterFrame", self )
                    self = nil -- flush self
                    self = -1 -- fill the gap in the table spawnedObstacles
                else
                    self.deathChosen = true -- this variable prevents from gibs spawning if the granny wasnt lucky enough to explode
                end
            else
                -- blood drip
                if 5 >= math.random(1,100) then
                    spawnDecal( "blood-stain2.png", self.x + math.random(2, self.width / 2), self.y + math.random(1,5)) -- if the granny hasnt exploded then it drips blood after shes dead
                end
            end
        end
    end

    function spawnPattern()
        local minRows = 4
        local maxRows = 10
        local aRandomSelection = math.random(100)
        if      aRandomSelection < 5 then
            zebraSpawnSystem()
        elseif  aRandomSelection < 25 then
            zigzagSpawnSystem(math.random(minRows,maxRows))
        elseif  aRandomSelection < 35 then
            upsideDownLSpawnSystem(math.random(2,6))
        elseif  aRandomSelection < 50 then
            heartBeatSpawnSystem(math.random(minRows,maxRows) * 2)
        elseif  aRandomSelection <= 90 then 
            randomSpawnSystem(math.random(minRows,maxRows))
        elseif  aRandomSelection <= 100 then
            constructionSiteSpawnSystem()
        end
    end

    function isLastObstacleBellowX( self, event )
        if self[#self] ~= nil and self[#self].y > (display.contentHeight / 2) then
            spawnPattern()
        end
    end

    spawnedObstacles.enterFrame = isLastObstacleBellowX
    Runtime:addEventListener("enterFrame", spawnedObstacles)

    -- spawnObstacle(obstacleNames[4], 3)
    -- heartBeatSpawnSystem(50)
    -- zebraSpawnSystem()
    -- constructionSiteSpawnSystem()
    spawnPattern() -- initial spawning at the start of the round
    -----END OBSTACLE SPAWNING-------------------------------------------------------------------


    ----Obstacle interaction V 0.1(square based interaction)---------------------------------------------------------------
    money = 0

    physics.addBody( car, "static" )
    car.gravityScale = 0
    group:insert(car)

    local moneyCollectedTexts = {}
    local function removeMoneyCollectedText( event )
        moneyCollectedTexts[1]:removeSelf()
        table.remove(moneyCollectedTexts, 1)
    end

    local swayCounter = 0
    local isCarSwaying = false

    local function swayCarRight(transitionDistance, transitionTime)
        transition.to(car, {time = transitionTime, rotation = 45, x=car.x + transitionDistance, onComplete = swayCar} )
    end

    local function swayCarLeft(transitionDistance, transitionTime)
        transition.to(car, {time = transitionTime, rotation = -45, x=car.x - transitionDistance, onComplete = swayCar} )
    end

    function swayCar( obj )
        playerHasControl = false
        isCarSwaying = true
        swayCounter = swayCounter + 1
        
        -- excecutes swaying (left or right) 3 times then sets the counter to 0
        if swayCounter == 1 then
            swayCarLeft(50, 200)
        elseif swayCounter == 2 then
            swayCarRight(90, 250)
        elseif swayCounter == 3 then
            swayCarLeft(40, 100)
        else
            swayCounter = 0
            if isRoundOver == false then 
                playerHasControl = true
                isCarSwaying = false
            end
        end
    end

    local function removeCollisionWithCar ( self )
        local carCollisionFilter = { categoryBits = 2, maskBits = 0 }
        physics.removeBody( self )
        physics.addBody( self, "dynamic", {filter = carCollisionFilter} )
        self.gravityScale = 0
    end

    local spawnedGibs = {}                                                      -- all gib objects are held in here. Gnarly
    local gibsCollisionCollisionFilter = { categoryBits = 3, maskBits = 0 }     -- and they don't collide with anything!

    local spawnedEmitters = {}
    local previousAngle = 0

    function moveGibs( self, event )
        self.speed = carSpeed
        
        -- rotate emitters
        spawnedEmitters[self.index].x = spawnedGibs[self.index].x
        spawnedEmitters[self.index].y = spawnedGibs[self.index].y
        
        
        spawnedEmitters[self.index].rotation = spawnedGibs[self.index].rotation
        if  self.y > display.contentHeight + 32 then
            display.remove(spawnedEmitters[self.index])
            spawnedEmitters[self.index] = nil                   -- flush
            spawnedEmitters[self.index] = -1                    -- fill the gap
            self:removeSelf()                                   -- removes image
            Runtime:removeEventListener( "enterFrame", self )   -- removes physicical properties
            self = nil                                          -- flush self
            self = -1                                           -- fill the gap in the table spawnedObstacles
        elseif isRoundOver == false then                        -- stops obstacle movement if the round is over
            self.y = (self.y + self.speed)
        end
    end
    
    local splashGibSound = audio.loadSound( "granny squish.mp3")
    function spawnGibs(self)
        local splashGibChannel = audio.play( splashGibSound )
        if self.gibsSplashes == nil then
            if slowMotionActivated == false then
                OGSpeed = carSpeed
                Runtime:addEventListener("enterFrame", slowMotion)
            end
            local randomAmountOfGibs = math.random(1,5)
            local generatedNumbers = {}
            for i = 1, randomAmountOfGibs do
                self.gibsSplashes = true                    -- dont spawn anymore gibs for this granny baus
                
                -- gib declaration
                local indexToPlaceIn = #spawnedGibs + 1
                
                local uniqueNumber = -1
                while uniqueNumber == -1 do
                    uniqueNumber = math.random(1,5)
                    for i = 1, #generatedNumbers do
                        if uniqueNumber == generatedNumbers[i] then
                            uniqueNumber = -1
                        end
                    end
                end
                table.insert(generatedNumbers, uniqueNumber)
                
                local gibImageNames = {"leg1.png", "leg2.png", "arm1.png", "arm2.png", "grannyHead.png"}
                spawnedGibs[indexToPlaceIn] = display.newImage(gibImageNames[uniqueNumber])
                physics.addBody( spawnedGibs[indexToPlaceIn], "dynamic", {filter = gibsCollisionCollisionFilter, friction = 100.0} )
                spawnedGibs[indexToPlaceIn].x = self.x
                spawnedGibs[indexToPlaceIn].y = self.y
                spawnedGibs[indexToPlaceIn].index = indexToPlaceIn
                spawnedGibs[indexToPlaceIn].gravityScale = 1
                group:insert(spawnedGibs[indexToPlaceIn])
                
                -- assigning the gib random movement
                local randomXForce = math.random(-10,10) / 100 * (carSpeed / 2)        -- a random value between left and right forces
                local randomYForce = math.random(0,5) / 100 --* (carSpeed - minCarSpeed * 10)                            -- a random value for slight upward force
                spawnedGibs[indexToPlaceIn]:applyLinearImpulse( randomXForce, randomYForce, spawnedGibs[indexToPlaceIn].x, spawnedGibs[indexToPlaceIn].y ) -- applies forces
                
                -- assigning the gib rotation
                local randomRotation = randomXForce * 5                               -- left or right force turned into rotation number
                spawnedGibs[indexToPlaceIn]:applyAngularImpulse( randomRotation )       -- applies rotation
                spawnedGibs[indexToPlaceIn].enterFrame = moveGibs                       -- moves gibs back depending on car speed (kind of like wind slowing them down)
                Runtime:addEventListener("enterFrame", spawnedGibs[indexToPlaceIn])
                
                -- assigning emitter to the gib
                spawnedEmitters[indexToPlaceIn] = particleDesigner.newEmitter( "blood.json" )
                spawnedEmitters[indexToPlaceIn].x = spawnedGibs[indexToPlaceIn].x + spawnedGibs[indexToPlaceIn].height / 2
                spawnedEmitters[indexToPlaceIn].y = spawnedGibs[indexToPlaceIn].y + spawnedGibs[indexToPlaceIn].width / 2
                group:insert(spawnedEmitters[indexToPlaceIn])
            end
        end
    end

    local mudStains = {}

    function splashMud( event )
        local percentageToSplashMud = 40 - (100 * defenseUpgrade)
        if percentageToSplashMud >= math.random( 1, 100 ) and isRoundOver == false then
            local indexToPlaceIn = #mudStains + 1
            mudStains[indexToPlaceIn] = display.newImage("mud-splash.png")
            mudStains[indexToPlaceIn].x = math.random( 54, display.contentWidth - 54 )
            mudStains[indexToPlaceIn].y = math.random( 0, display.contentHeight - 100 )
            local randomScaleNumber = math.random(3, 5)
            mudStains[indexToPlaceIn]:scale( randomScaleNumber, randomScaleNumber )
            mudStains[indexToPlaceIn].rotation = math.random( 1, 360 )
            transition.to( mudStains[indexToPlaceIn], { time = 2500, delay = 1500, alpha = 0, y = mudStains[indexToPlaceIn].y + 50 * randomScaleNumber} )
        end
    end

    keepSplashing = false

    function collideWithMud()
        if keepSplashing == false then
            keepSplashing = true
            
            Runtime:addEventListener( "enterFrame", splashMud )     -- create event
        else
            keepSplashing = false
            
            Runtime:removeEventListener( "enterFrame", splashMud )  -- remove event
        end
    end

    leftTireBursted = false
    rightTireBursted = false
    local tyreChannel = audio.loadSound("tyre burst.mp3")
    
    function burstLeftTire()
        if leftTireBursted == false then
            if rightTireBursted == true then
                burstedTirePenalty = 0.25
                additionalRotation = 0
                local tyreHitChannel = audio.play( tyreChannel )
            else
                burstedTirePenalty = 0.5
                additionalRotation = -20 * (1 - handlingUpgrade / 3 * 0.6)
                local tyreHitChannel = audio.play( tyreChannel )
            end
        end
        leftTireBursted = true
    end

    function burstRightTire()
        if rightTireBursted == false then
            if leftTireBursted == true then
                burstedTirePenalty = 0.25
                additionalRotation = 0
                local tyreHitChannel = audio.play( tyreChannel )
            else
                burstedTirePenalty = 0.5
                additionalRotation = 20 * (1 - handlingUpgrade / 3 * 0.6)
                local tyreHitChannel = audio.play( tyreChannel )
            end
        end
        rightTireBursted = true
    end

    local grannyHit = audio.loadSound ( "granny hit.mp3" )
    
    local function onCollision( car, event )
        if event.other.hasCollided == false then
            if event.other.obstacleName == "granny" then
                spawnDecal( "blood-stain1.png", event.other.x, event.other.y + event.other.height * 0 ) -- spawns the pool of blood
                event.other:toFront()
                event.other.dead = true                                                 -- tells the game she's dead, which will cause the gibs to fly around
                moneyCollectedTexts[#moneyCollectedTexts + 1] = display.newText( math.floor((0.25*(carSpeed*10))) .. "$", event.other.x, event.other.y - 20, "Comic Sans MS", 20 ) -- shows how much money is obtained from the granny
                moneyCollectedTexts[#moneyCollectedTexts]:setFillColor( 0, 0.7, 0, 1 )  -- turns text green 
                timer.performWithDelay( 200, removeMoneyCollectedText )                 -- removes text
                money = money + (0.25*(carSpeed*10))                                    -- increases money
                event.other:pause()
                local grannyHitChannel = audio.play( grannyHit )
            elseif event.other.obstacleName == "traffic-cone.png" or event.other.obstacleName == obstacleNames[7] then
                carSpeed = carSpeed * (coneSlowDown + defenseUpgrade)
            elseif event.other.obstacleName == "manHole" then
                local passParameter = function() removeCollisionWithCar ( event.other ) end
                timer.performWithDelay( 1, passParameter )
                if isCarSwaying == false then
                    swayCar()
                end
            elseif event.other.obstacleName == obstacleNames[5] then
                carSpeed = carSpeed * (0.2 + defenseUpgrade)
            elseif event.other.obstacleName  ~= obstacleNames[3] and event.other.obstacleName ~= obstacleNames[4] and event.other.obstacleName ~= goodItemNames[2] then
                roundOver()
            end
            car:toFront()
        end
        if event.other.obstacleName == obstacleNames[3] then
            collideWithMud()
        end
        event.other.hasCollided = true
        if event.other.obstacleName == goodItemNames[2] then
            if (fuel + 50) < maxFuel then
                fuel = fuel + fuelAdded
            else
                fuel = maxFuel
            end
            
            event.other:removeSelf()
            Runtime:removeEventListener( "enterFrame", event.other )
            event.other = nil -- flush self
            event.other = -1 -- fill the gap in the table spawnedObstacles
        end
    end

    -- Creates an event for the car
    car.collision = onCollision
    car:addEventListener( "collision", car )
    ------------------not Finished------------------------------------------------------------------------------------



    ------HUD-------------------------------------------------------------------------------------------
    maxSpeed = 20 -- watch out brotha! 40 pixels not kmh
    local isScreenCracked = false
    
    local moneyEarnedHUDText = display.newText( "$" .. money, display.contentWidth - 25, display.contentHeight - 25, "Comic Sans MS", 12 )
    group:insert(moneyEarnedHUDText)

    local speedometerBase = display.newImage("SpeedBase1.png")
    speedometerBase.anchorY = 1
    speedometerBase.x = display.contentWidth / 2
    speedometerBase.y = display.contentHeight
    local speedometerArrow = display.newImage("SpeedArrow.png")
    speedometerArrow.anchorY = 0.85
    speedometerArrow.x = display.contentWidth / 2
    speedometerArrow.y = display.contentHeight
    speedometerArrow.rotation = carSpeed / maxSpeed * 180 - 90 -- percetage of max speed turned into degrees
    local crackedScreen = display.newImage("SpeedBase1Crack.png")
    crackedScreen.anchorY = 1
    crackedScreen.x = speedometerBase.x
    crackedScreen.y = speedometerBase.y
    group:insert(crackedScreen)
    group:insert(speedometerBase)
    group:insert(speedometerArrow)
    
    local fuelHUDTank = display.newImage("tank.png")
    fuelHUDTank.anchorY = 1
    fuelHUDTank.x = 26
    fuelHUDTank.y = display.contentHeight - 10
    local fuelHUDIndicator = display.newImage("fuel-hud-indicator.png")
    fuelHUDIndicator.anchorY = 1
    fuelHUDIndicator.x = 26
    fuelHUDIndicator.y = display.contentHeight - 10
    group:insert(fuelHUDTank)
    group:insert(fuelHUDIndicator)
    
    
    --local fuelHUDText
    function updateHUD()
        if isRoundOver == false then
            moneyEarnedHUDText.text = math.floor(money) .. "$"
            
            fuelHUDIndicator.yScale = fuel / maxFuel
            fuelHUDTank:toFront()
            
            if slowMotionActivated == true then -- rotates the speedometer arrow
                speedometerArrow.rotation = OGSpeed / maxSpeed * 180 - 90 -- percetage of max speed turned into degrees
            else
                speedometerArrow.rotation = carSpeed / maxSpeed * 180 - 90 -- percetage of max speed turned into degrees
            end
            
            if speedometerArrow.rotation > 90 then -- sets limit to rotation
                speedometerArrow.rotation = 90
                
                isScreenCracked = true
            end
            speedometerBase:toFront()
            speedometerArrow:toFront()
            if isScreenCracked then
                crackedScreen:toFront()
            end
            for i=1, #mudStains do
                mudStains[i]:toFront()
            end
        end
    end

    Runtime:addEventListener("enterFrame", updateMovement)
    Runtime:addEventListener("enterFrame", updateHUD)
    ------HUD END---------------------------------------------------------------------------------------
    
    function clearPhysicsBodies()
        physics.removeBody(car)
        for i = 1, #spawnedObstacles do
            print("index: " .. i .. "; isOffScreen: ")
            print(spawnedObstacles[i].isOffScreen)
            -- if spawnedObstacles[i].isOffScreen ~= true and spawnedObstacles[i].isOffScreen ~= nil then
            --     physics.removeBody(spawnedObstacles[i])
            -- end
        end
    end

    -- roundOver() gets called when the defeat condition is met e.g. running out of fuel
    function roundOver ()
        if isRoundOver == false then
            isRoundOver = true
            playerHasControl = false
            
            local background2 = display.newImage("title background.jpg")
            background2.x = display.contentWidth / 2
            background2.y = display.contentHeight / 2
            group:insert(background2)

            local youLooseImage = display.newImage("youloose.png")
            youLooseImage.x = (display.contentWidth / 2)
            youLooseImage.y = (display.contentHeight / 2 - 150)
            group:insert(youLooseImage)
            
            local insults = {
                "You drive slower than my granny!!!",
                "Sorry grandma, no Bingo today!",
                "Meh..",
                "Your grandma would be dissapointed!",
                "...",
                "You score just above the lowest 10%. Nice!",
                "Wow buddy, that was fast huh?!",
                "Arrow keys to move, just so you know.",
                "git gud"
            }
            
            local insultDisplayed = display.newText ( insults[math.random(1,#insults)], (display.contentWidth / 2), (display.contentHeight / 2 - 100), "Comic Sans MS", 15 )
            insultDisplayed:setFillColor(1, 1, 0, 1)
            group:insert(insultDisplayed)
            
            local calculateMoney = (composer.getVariable("globalMoney") + money)
            composer.setVariable("globalMoney", calculateMoney)
            
            local backToMenu = display.newImage( "back to menu.png" )
            backToMenu.x = 100
            backToMenu.y = 250
            backToMenu.width = 100
            backToMenu.height = 35
            group:insert(backToMenu)
            local function onBackTouch( event )
                if ( event.phase == "began" ) then
                    clearPhysicsBodies()
                    composer.removeScene("game")
                    composer.gotoScene("menu")
                end
                return true
            end
            backToMenu:addEventListener( "touch", onBackTouch )
            
            local upgrades = display.newImage("upgrades.png")
            upgrades.x = 220
            upgrades.y = 250
            upgrades.width = 100
            upgrades.height = 40
            group:insert(upgrades)
            local function onUpgradeTouch( event )
                if ( event.phase == "began" ) then
                    clearPhysicsBodies()
                    composer.removeScene("game")
                    composer.gotoScene("upgrades")
                end
                return true
            end
            upgrades:addEventListener( "touch", onUpgradeTouch )
            
            local playAgain = display.newImage("playagainbutton.png")
            playAgain.x = 160
            playAgain.y = 200
            playAgain.width = 100
            playAgain.height = 40
            group:insert(playAgain)
            local function playAgainTouch( event )
                if ( event.phase == "began" ) then
                    clearPhysicsBodies()
                    composer.removeScene("game")
                    composer.gotoScene("loading")
                end
                return true
            end
            playAgain:addEventListener( "touch", playAgainTouch )
        end
    end
end
function scene:show(event)
end
function scene:destroy(event)
end
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("destroy", scene)

return scene