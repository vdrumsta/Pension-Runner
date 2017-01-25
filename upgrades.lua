local composer = require ("composer")
local scene = composer.newScene()
local M = {}
function scene:create(event)
	local group = self.view
	local fuelUpgrade = composer.getVariable("setFuelUpgrade")  
	local defenseUpgrade = composer.getVariable("setDefenseUpgrade")   
	local accelerationUpgrade = composer.getVariable("setAccelerationUpgrade") 	
	local handlingUpgrade = composer.getVariable("setHandlingUpgrade")
	local background = display.newImage( "shop.png" )
	background.x = 160
	background.y = 240
	background.width = 320
	background.height = 480
	group:insert(background)
	local backToMenu = display.newImage( "back to menu.png" )
	backToMenu.x = 75
	backToMenu.y = 35
	backToMenu.width = 60
	backToMenu.height = 35
	group:insert(backToMenu)
    
    -- upgrade costs
    local prices = {}
    prices = {50, 100, 250, 500, 10000, "MAX"}
    local fuelCost          = fuelUpgrade + 1
    local defenseCost       = defenseUpgrade / 0.14 + 1
    local accelerationCost  = accelerationUpgrade + 1
    local handlingCost      = handlingUpgrade / 0.6 + 1
    
    -- upgrade Buttons
    local upgradesX = 280 -- x position of button placement
    local fuelUpgradeButton = 0 -- declaring
    if fuelUpgrade >= 5 then -- if its upgraded to 5 then display max image, otherwise a plus image
        fuelUpgradeButton = display.newImage("max.png")
    else
        fuelUpgradeButton = display.newImage("plus.png")
    end
	fuelUpgradeButton.x = upgradesX
	fuelUpgradeButton.y = 280
    fuelUpgradeButton.width = 80
    fuelUpgradeButton.height = 45
	group:insert(fuelUpgradeButton)
    
	local defenseUpgradeButton = 0
    if defenseUpgrade >= 0.7 then
        defenseUpgradeButton = display.newImage("max.png")
    else
        defenseUpgradeButton = display.newImage("plus.png")
    end
	defenseUpgradeButton.x = upgradesX
	defenseUpgradeButton.y = 330
    defenseUpgradeButton.width = 80
    defenseUpgradeButton.height = 45
	group:insert(defenseUpgradeButton)
    
    local accelerationUpgradeButton = 0
    if accelerationUpgrade >= 5 then
        accelerationUpgradeButton = display.newImage("max.png")
    else
        accelerationUpgradeButton = display.newImage("plus.png")
    end
	accelerationUpgradeButton.x = upgradesX
	accelerationUpgradeButton.y = 380
    accelerationUpgradeButton.width = 80
    accelerationUpgradeButton.height = 45
	group:insert(accelerationUpgradeButton)
    
    local handlingUpgradeButton = 0
    if handlingUpgrade >= 3 then
        handlingUpgradeButton = display.newImage("max.png")
    else
        handlingUpgradeButton = display.newImage("plus.png")
    end
	handlingUpgradeButton.x = upgradesX
	handlingUpgradeButton.y = 430
    handlingUpgradeButton.width = 80
    handlingUpgradeButton.height = 45
	group:insert(handlingUpgradeButton)
    
    -- upgrade text
    local fuelUpgradeText = display.newText ( "Fuel: " .. fuelUpgrade, (display.contentWidth - 100), fuelUpgradeButton.y, "Comic Sans MS", 15 )
    local fuelUpgradeCost = display.newText ( "$" .. prices[fuelCost], (fuelUpgradeText.x - fuelUpgradeText.width / 2 - 90), fuelUpgradeButton.y, "Comic Sans MS", 15 )
    group:insert(fuelUpgradeText)
    group:insert(fuelUpgradeCost)
    
    local defenseUpgradeText = display.newText ( "Defense: " .. defenseUpgrade / 0.14, (display.contentWidth - 114), defenseUpgradeButton.y, "Comic Sans MS", 15 )
    local defenseUpgradeCost = display.newText ( "$" .. prices[defenseCost], (fuelUpgradeText.x - fuelUpgradeText.width / 2 - 90), defenseUpgradeButton.y, "Comic Sans MS", 15 )
    group:insert(defenseUpgradeText)
    group:insert(defenseUpgradeCost)
    
    local accelerationUpgradeText = display.newText ( "Acceleration: " .. accelerationUpgrade, (display.contentWidth - 130), accelerationUpgradeButton.y, "Comic Sans MS", 15 )
    local accelerationUpgradeCost = display.newText ( "$" .. prices[accelerationCost], (fuelUpgradeText.x - fuelUpgradeText.width / 2 - 90), accelerationUpgradeButton.y, "Comic Sans MS", 15 )
    group:insert(accelerationUpgradeText)
    group:insert(accelerationUpgradeCost)
    
    local handlingUpgradeText = display.newText ( "Handling: " .. handlingUpgrade / 0.6, (display.contentWidth - 114), handlingUpgradeButton.y, "Comic Sans MS", 15 )
    local handlingUpgradeCost = display.newText ( "$" .. prices[handlingCost], (fuelUpgradeText.x - fuelUpgradeText.width / 2 - 90), handlingUpgradeButton.y, "Comic Sans MS", 15 )
    group:insert(handlingUpgradeText)
    group:insert(handlingUpgradeCost)
    
    local moneyDisplay = display.newText ( "Money: $" .. math.floor(composer.getVariable("globalMoney")), (display.contentWidth / 2), (display.contentHeight / 2), 250, 100, "Comic Sans MS", 15 )
	group:insert(moneyDisplay)
    
    local function onBackTouch( event )
		if ( event.phase == "began" ) then
            composer.removeScene("upgrades")
			composer.gotoScene("menu")
		end
		return true
	end
	backToMenu:addEventListener( "touch", onBackTouch )
	
	local function onFuelTouch( event )
		if ( event.phase == "began" ) then
            local deductedMoney = composer.getVariable("globalMoney") - prices[fuelCost]
            
            if fuelUpgrade < 5 and deductedMoney >= 0 then
                fuelUpgrade = fuelUpgrade + 1           -- increment upgrades
                fuelCost    = fuelUpgrade + 1    -- increment cost
                
                composer.setVariable("setFuelUpgrade", fuelUpgrade)     -- set fuel upgrade globally
                composer.setVariable("globalMoney", deductedMoney)   -- set global money   
                moneyDisplay.text = "Money: $" .. math.floor(deductedMoney)
                
                fuelUpgradeText.text = "Fuel: " .. fuelUpgrade  -- set new upgrade text
                fuelUpgradeCost.text = "$" .. prices[fuelCost]  -- set new price text
                
                if fuelUpgrade >= 5 then -- change the button to max if it's the last upgrade
                    fuelUpgradeButtonX = fuelUpgradeButton.x
                    fuelUpgradeButtonY = fuelUpgradeButton.y
                    fuelUpgradeButton:removeSelf()
                    fuelUpgradeButton = nil
                    fuelUpgradeButton = display.newImage("max.png")
                    fuelUpgradeButton.x = fuelUpgradeButtonX
                    fuelUpgradeButton.y = fuelUpgradeButtonY
                    fuelUpgradeButton.width = 80
                    fuelUpgradeButton.height = 45
                    group:insert(fuelUpgradeButton)
                end
            end
		end
		return true
	end
	fuelUpgradeButton:addEventListener( "touch", onFuelTouch)

	local function onDefenseTouch( event )
		if ( event.phase == "began" ) then
            local deductedMoney = composer.getVariable("globalMoney") - prices[defenseCost]
            
            if defenseUpgrade < 0.7 and deductedMoney >= 0 then
                defenseUpgrade = defenseUpgrade + 0.14      -- increment upgrades
                defenseCost    = defenseUpgrade / 0.14 + 1  -- increment cost
                moneyDisplay.text = "Money: $" .. math.floor(deductedMoney)
                
                composer.setVariable("setDefenseUpgrade", defenseUpgrade)   -- set fuel upgrade globally
                composer.setVariable("globalMoney", deductedMoney)       -- set global money    
                defenseUpgradeText.text = "Defense: " .. (defenseUpgrade / 0.14)    -- set new upgrade text
                defenseUpgradeCost.text = "$" .. prices[defenseCost]       -- set new price text
                
                if defenseUpgrade >= 0.7 then -- change the button to max if it's the last upgrade
                    defenseUpgradeButtonX = defenseUpgradeButton.x
                    defenseUpgradeButtonY = defenseUpgradeButton.y
                    defenseUpgradeButton:removeSelf()
                    defenseUpgradeButton = nil
                    defenseUpgradeButton = display.newImage("max.png")
                    defenseUpgradeButton.x = defenseUpgradeButtonX
                    defenseUpgradeButton.y = defenseUpgradeButtonY
                    defenseUpgradeButton.width = 80
                    defenseUpgradeButton.height = 45
                    group:insert(defenseUpgradeButton)
                end
            end
		end
		return true
	end
	defenseUpgradeButton:addEventListener( "touch", onDefenseTouch)
	
	local function onAccelerationTouch( event )
		if ( event.phase == "began" ) then
            local deductedMoney = composer.getVariable("globalMoney") - prices[accelerationCost]
            
            if accelerationUpgrade < 5 and deductedMoney >= 0 then
                accelerationUpgrade = accelerationUpgrade + 1           -- increment upgrades
                accelerationCost    = accelerationUpgrade + 1    -- increment cost
                
                composer.setVariable("setAccelerationUpgrade", accelerationUpgrade)     -- set acceleration upgrade globally
                composer.setVariable("globalMoney", deductedMoney)   -- set global money
                moneyDisplay.text = "Money: $" .. math.floor(deductedMoney)
                
                accelerationUpgradeText.text = "Acceleration: " .. accelerationUpgrade  -- set new upgrade text
                accelerationUpgradeCost.text = "$" .. prices[accelerationCost]  -- set new price text
                
                if accelerationUpgrade >= 5 then -- change the button to max if it's the last upgrade
                    accelerationUpgradeButtonX = accelerationUpgradeButton.x
                    accelerationUpgradeButtonY = accelerationUpgradeButton.y
                    accelerationUpgradeButton:removeSelf()
                    accelerationUpgradeButton = nil
                    accelerationUpgradeButton = display.newImage("max.png")
                    accelerationUpgradeButton.x = accelerationUpgradeButtonX
                    accelerationUpgradeButton.y = accelerationUpgradeButtonY
                    accelerationUpgradeButton.width = 80
                    accelerationUpgradeButton.height = 45
                    group:insert(accelerationUpgradeButton)
                end
            end
		end
	end
	accelerationUpgradeButton:addEventListener( "touch", onAccelerationTouch)
	
	local function onHandlingTouch( event )
		if ( event.phase == "began" ) then
            local deductedMoney = composer.getVariable("globalMoney") - prices[handlingCost]
            
            if handlingUpgrade < 3 and deductedMoney >= 0 then
                handlingUpgrade = handlingUpgrade + 0.6      -- increment upgrades
                handlingCost    = handlingUpgrade / 0.6 + 1  -- increment cost
                
                composer.setVariable("setHandlingUpgrade", handlingUpgrade)   -- set fuel upgrade globally
                composer.setVariable("globalMoney", deductedMoney)       -- set global money    
                moneyDisplay.text = "Money: $" .. math.floor(deductedMoney)
                
                handlingUpgradeText.text = "Handling: " .. (handlingUpgrade / 0.6)    -- set new upgrade text
                handlingUpgradeCost.text = "$" .. prices[handlingCost]       -- set new price text
                
                if handlingUpgrade >= 3 then -- change the button to max if it's the last upgrade
                    handlingUpgradeButtonX = handlingUpgradeButton.x
                    handlingUpgradeButtonY = handlingUpgradeButton.y
                    handlingUpgradeButton:removeSelf()
                    handlingUpgradeButton = nil
                    handlingUpgradeButton = display.newImage("max.png")
                    handlingUpgradeButton.x = handlingUpgradeButtonX
                    handlingUpgradeButton.y = handlingUpgradeButtonY
                    handlingUpgradeButton.width = 80
                    handlingUpgradeButton.height = 45
                    group:insert(handlingUpgradeButton)
                end
            end
		end
		return true
	end
	handlingUpgradeButton:addEventListener( "touch", onHandlingTouch)
	
	-- function M.save()
		-- local path = system.pathForFile( "saveData.txt", system.DocumentsDirectory )
		-- local file = io.open( path, "w" )
		-- if( file )then
			-- local contents = tostring( onTouch, ontTouch1, onTouch2, onTouch3)
			-- file:write( contents )
			-- io.close( file )
			-- return true
		-- end
	-- end
	
	-- function M.load()
			-- local path = system.pathForFile( "saveData.txt", system.DocumentsDirectory )
			-- local contents = ""
			-- local file = io.open( path, "r" )
			-- if ( file ) then
			-- Read all contents of file into a string
				-- local contents = file:read( "*a" )
				-- local onTouch = tonumber(contents);
				-- io.close( file )
				-- return score
			-- end
	-- end
end

function scene:show(event)
end
scene:addEventListener("show", scene)
scene:addEventListener("create", scene)

return scene