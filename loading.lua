local composer = require ("composer")
local scene = composer.newScene()
function scene:create(event)
	local group = self.view
	local background = display.newImage( "background.png" )
	background.x = 160
	background.y = 240
	background.width = 320
	background.height = 480
	group:insert(background)
	composer.removeScene("game")
	composer.gotoScene("game")
	composer.removeScene("loading") 
end
function scene:show(event)
end
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)

return scene