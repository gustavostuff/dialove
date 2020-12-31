local Dialove = require('Dialove')

function love.load()
  canvas = love.graphics.newCanvas(384, 216)
  canvas:setFilter('nearest', 'nearest')
  dialogManager = Dialove.init({
    --font = love.graphics.newFont('fonts/comic-neue/ComicNeue-Bold.ttf', 20),
    --font = love.graphics.newFont('fonts/press-start-2p/PressStart2P-Regular.ttf', 16),
    --font = love.graphics.newFont('fonts/seagram/Seagram tfb.ttf', 16),
    font = love.graphics.newFont('fonts/proggy-tiny/ProggyTiny.ttf', 16),
    --numberOfLines = 3,
    --typingVolume = 0.1,
    optionsSeparation = 10,
    viewportW = canvas:getWidth(),
    viewportH = canvas:getHeight(),
  })

  --dialogManager:setDebug(true)

  local function randomText()
    local texts = {
      "Hey, haven't we met before? Your face certainly looks familiar to me.",
      "I live a couple of blocks away, we just moved to the city and you the first person I talk to...",
      "Yes, I'm getting transferred to that same school actually, I'll see you there!",
      "Well, we just met but you seem like a nice guy so, yes, I guess it's ok to go for a drink.",
      "Well, you turned out to be a jerk, please don't talk to me anymore.",
      "I don't have a boyfriend... do you have a girlfriend?",
      "Sorry, I think that crosses the line, maybe I should go...",
      "Sure, I'll see you around!",
    }
    return texts[love.math.random(1, #texts)]
  end

  dialogManager:show({
    title = 'Title Dialog 1',
    text = 'Dialog 1: Press F to complete the dialog, Space bar to speed up and Enter to request the next one.',
    position = 'top',
    options = {
    {
      'Choose Dialog 2', function ()
        dialogManager:show('Dialog 2: ' .. randomText())
        dialogManager:push({text = 'Dialog 4: ' .. randomText(), autoHeight = true})
      end
    },
    {
      'Choose Dialog 3', function ()
        dialogManager:show({text = 'Dialog 3: ' .. randomText(), options = {
          {
            'Choose Dialog 5', function ()
              dialogManager:show('Dialog 5: ' .. randomText())
            end
          },
          {
            'Choose Dialog 6', function ()
              dialogManager:show({text = 'Dialog 6: ' .. randomText(), numberOfLines = 7})
            end
          }
        }})
      end
    }
  }})

  dialogManager:push('Dialog 7: ' .. randomText())

  dialogManager:push({text = 'Dialog 8: ' .. randomText(), options = {
    {
      'Choose Dialog 9', function ()
        dialogManager:show('Dialog 9: ' .. randomText())
        dialogManager:push('Dialog 10: ' .. randomText())
        dialogManager:push('Dialog 11: ' .. randomText())
        dialogManager:push('Dialog 12: ' .. randomText())
      end
    },
    {
      'Choose Dialog 13', function ()
        dialogManager:show('Dialog 13: ' .. randomText())
        dialogManager:push({
          title = 'Title',
          text = 'Dialog 14: ' .. randomText(),
          image = love.graphics.newImage('face.png')
        })
      end
    }
  }})

  randomColor = {love.math.random() / 2, love.math.random() / 2, love.math.random() / 2}
  love.graphics.setBackgroundColor(randomColor)
end

function love.update(dt)
  dialogManager:update(dt)
end

function love.draw()
  love.graphics.setCanvas{canvas, stencil = true}
  love.graphics.clear()
  dialogManager:draw()
  love.graphics.setCanvas()
  love.graphics.draw(canvas, 0, 0, 0, love.graphics.getWidth() / canvas:getWidth(), love.graphics.getHeight() / canvas:getHeight())
end

function love.keypressed(k)
  if k == 'return' then
    dialogManager:pop()
  elseif k == 'f' then
    dialogManager:complete()
  elseif k == 'space' then
    dialogManager:faster()
  elseif k == 'down' then
    dialogManager:changeOption(1) -- next one
  elseif k == 'up' then
    dialogManager:changeOption(-1) -- previous one
  end

  if k == 'escape' then
    love.event.quit()
  end
end

function love.keyreleased(k)
  if k == 'space' then
    dialogManager:slower()
  end
end