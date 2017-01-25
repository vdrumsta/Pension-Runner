local composer = require ("composer")
local scene = composer.newScene()
function scene:create(event)
	local group = self.view
	local background = display.newImage( "title background.jpg" )
	background.x = 160
	background.y = 240
	background.width = 320
	background.height = 480
	group:insert(background)
	local instructions = display.newImage( "instructions.png" )
	instructions.x = 160
	instructions.y = 225
	group:insert(instructions)
	local credits = display.newImage( "credits.png" )
	credits.x = 160
	credits.y = 380
	credits.width = 240
	credits.height = 120
	group:insert(credits)
	local backToMenu = display.newImage( "back to menu.png" )
	backToMenu.x = 75
	backToMenu.y = 35
	backToMenu.width = 60
	backToMenu.height = 35
	group:insert(backToMenu)
	local function onBackTouch( event )
		if ( event.phase == "began" ) then
			composer.gotoScene("menu")
		end
		return true
	end
    
    local function onCreditsTouch( event )
		if ( event.phase == "began" ) then
			composer.gotoScene("credits")
		end
		return true
	end
    
	backToMenu:addEventListener( "touch", onBackTouch )
	credits:addEventListener( "touch", onCreditsTouch )
end
function scene:show(event)
end
function scene:destroy(event)
end
scene:addEventListener("show", scene)
scene:addEventListener("create", scene)
scene:addEventListener("destroy", scene)
return scene
