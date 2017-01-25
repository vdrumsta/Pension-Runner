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
	local title = display.newImage("title.png")
	title.x = 160
	title.y = 90
	title.width = 240
	title.height = 110
	group:insert(title)
	local play = display.newImage("play button.png")
	play.x = 160
	play.y = 200
	play.width = 240
	play.height = 80
	group:insert(play)
	local function onPlayTouch( event )
		if ( event.phase == "began" ) then
        	composer.removeScene("game")
			composer.gotoScene("game", "fade", 100)
		end
		return true
	end
	play:addEventListener( "touch", onPlayTouch )
	local upgrades = display.newImage("upgrades.png")
	upgrades.x = 160
	upgrades.y = 300
	upgrades.width = 240
	upgrades.height = 80
	group:insert(upgrades)
	local function onUpgradeTouch( event )
		if ( event.phase == "began" ) then
			composer.gotoScene("upgrades")
		end
		return true
	end
	upgrades:addEventListener( "touch", onUpgradeTouch )
	local options = display.newImage("options.png")
	options.x = 160
	options.y = 400
	options.width = 240
	options.height = 80
	group:insert(options)
	local function onOptionsTouch( event )
		if ( event.phase == "began" ) then
			composer.gotoScene("options")
		end
		return true
	end
	options:addEventListener( "touch", onOptionsTouch )
end
function scene:show(event)

end
function scene:destroy(event)
	
end
scene:addEventListener("show", scene)
scene:addEventListener("create", scene)
scene:addEventListener("destroy", scene)

return scene
