local composer = require ("composer")
local scene = composer.newScene()
local widget = require "widget"
function scene:create(event)
	local group = self.view
	local background = display.newImage( "title background.jpg" )
	background.x = 160
	background.y = 240
	background.width = 320
	background.height = 480
	group:insert(background)
    function shrinkText()
        transition.to( title, {time = 10000, yScale = 1, xScale = 1, onComplete = enlargeText, transition = easing.inOutCubic})
    end
    function enlargeText()
        transition.to( title, {time = 10000, yScale = 1.3, xScale = 1.3, onComplete = shrinkText, transition = easing.inOutCubic})
    end
    function rotateTextAntiClockwise()
        transition.to( title, {time = 6000, rotation = -15, onComplete = rotateTextClockwise, transition = easing.inOutCubic})
    end
    function rotateTextClockwise()
        transition.to( title, {time = 6000, rotation = 15, onComplete = rotateTextAntiClockwise, transition = easing.inOutCubic})
    end
    function moveText()
        enlargeText()
        rotateTextClockwise()
    end
	title = display.newImage("title.png")
	title.x = 160
	title.y = 150
	title.width = 240
	title.height = 100
	group:insert(title)
    moveText( title )
	local function playButton()
		composer.gotoScene( "menu")
		return true
	end
	local playbuttonplacement = display.newImage("startgame.png")
	playbuttonplacement.x = display.contentWidth / 2
	playbuttonplacement.y = display.contentHeight - 100
	playbuttonplacement:scale( 0.7, 0.7 )
	group:insert(playbuttonplacement)
	local function onPlayTouch( event )
		if ( event.phase == "began" ) then
        	composer.removeScene("title")
			composer.gotoScene("menu", "fade", 100)
		end
		return true
	end
	playbuttonplacement:addEventListener( "touch", onPlayTouch )
end
function scene:show(event)
end
function scene:destroy(event)
end
scene:addEventListener("show", scene)
scene:addEventListener("create", scene)
scene:addEventListener("destroy", scene)

return scene
