local composer = require ("composer")
local scene = composer.newScene()
function scene:create(event)
    local background = display.newImage("background.png")
    local group = self.view
    background.x = 160
	background.y = 240
	background.width = 320
	background.height = 480
	group:insert(background)
    local play = display.newImage("play button.png")
	play.x = 160
	play.y = 200
	play.width = 240
	play.height = 80
	group:insert(play)
    local function onPlayTouch( event )
		if ( event.phase == "began" ) then
			composer.gotoScene("game")
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
end