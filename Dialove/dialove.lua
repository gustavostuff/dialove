--[[
  Copyright 2020 Gustavo Lara
  
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
  associated documentation files (the "Software"), to deal in the Software without restriction,
  including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
  OR OTHER DEALINGS IN THE SOFTWARE.
]]


-- Utilities
-- ############################################################

local timer = {
  list = {}
}

timer.new = function (key, delay)
  timer.list[key] = {
    delay = delay,
    timerCount = 0,
    enabled = true
  }
end

timer.isTimeTo = function (key, dt)
  local t = timer.list[key]

  if not t or not t.enabled then
    return false
  end

  t.timerCount = t.timerCount + dt

  if t.timerCount >= t.delay then
    t.timerCount = 0
    t.enabled = false
    return true
  end
end

timer.completeIteration = function (key)
  local t = timer.list[key]

  if t then
    t.timerCount = t.delay
  end
end

timer.setDelay = function (key, delay)
  local t = timer.list[key]

  if t then
    t.delay = delay
  end
end

local colors = {
  alphaBlack = {0, 0, 0, 0.7},
  white = {1, 1, 1},
  gray = {0.5, 0.5, 0.5},
  green = {0, 1, 0},
  red = {1, 0, 0},
  yellow = {1, 1, 0},
  orange = {1, 0.5, 0},
}

-- for all cases, manager has global stuff, dialog has data just for the current one
local normalBackgroundStencil = function (manager, dialog)
  return function ()
    love.graphics.setColor(colors.white)
    love.graphics.rectangle('fill',
      math.floor(manager.margin),
      math.floor(dialog.y + manager.margin),
      math.floor(manager.viewportW - manager.margin * 2),
      math.floor(dialog.backgroundH),
      manager.cornerRadius,
      manager.cornerRadius
    )

    if dialog.title then
      local titleBackgroundY = dialog.y + manager.margin - (manager.lineHeight)

      if dialog.top then
        titleBackgroundY = dialog.y + dialog.height - manager.margin - manager.lineHeight
      end

      love.graphics.rectangle('fill',
        math.floor(manager.margin),
        math.floor(titleBackgroundY),
        math.floor(manager.font:getWidth(dialog.title) + manager.padding * 2),
        math.floor(manager.lineHeight * 2),
        manager.cornerRadius,
        manager.cornerRadius
      )
    end
  end
end

local drawBackground = function (manager, dialog)
  love.graphics.stencil(normalBackgroundStencil(manager, dialog), "replace", 1)
  love.graphics.setStencilTest("greater", 0)

  love.graphics.setColor(manager.bgColor)
  love.graphics.rectangle('fill', 0, 0, manager.viewportW, manager.viewportH)

  love.graphics.setStencilTest()

  if manager.debug then
    love.graphics.setColor(colors.orange)
    love.graphics.rectangle('line', 0, dialog.y, manager.viewportW, dialog.height)
    love.graphics.setColor(colors.yellow)
    love.graphics.rectangle('line',
      manager.margin,
      dialog.y + manager.margin,
      manager.viewportW - manager.margin * 2,
      dialog.height - manager.margin * 2
    )

    if manager.debug and dialog.title then
      local titleBackgroundY = dialog.y + manager.margin - (manager.lineHeight)
      if dialog.top then
        titleBackgroundY = dialog.y + dialog.height - manager.margin - manager.lineHeight
      end

      love.graphics.rectangle('line',
        math.floor(manager.margin),
        math.floor(titleBackgroundY),
        math.floor(manager.font:getWidth(dialog.title) + manager.padding * 2),
        math.floor(manager.lineHeight * 2)
      )
    end
  end
end

local calculateLineY = function (manager, dialog)
  local lineY = dialog.y + manager.margin + manager.padding
  return lineY
end

local printTitle = function (manager, dialog)
  if not dialog.title then return end

  love.graphics.setColor(manager.fgColor)
  local titleY = dialog.y + manager.margin - manager.lineHeight / 2
  if dialog.top then
    titleY = dialog.y + dialog.height - manager.margin
  else
    titleY = titleY - (manager.font:getHeight() / 4)
  end

  love.graphics.print(dialog.title, math.floor(manager.margin + manager.padding), math.floor(titleY))
end

local printText = function (manager, dialog, firstLine, lastLine, completeLine)
  local lineY = 0
  for n = firstLine, lastLine do
    local line = dialog.lines[n]
    local lineX = math.floor(manager.margin + manager.padding)

    if dialog.image then
      lineX = lineX + dialog.image:getWidth() + manager.padding
    end

    if not line then goto continue end
    lineY = calculateLineY(manager, dialog)

    love.graphics.setColor(manager.fgColor)
    love.graphics.print(line:sub(1, (function ()
      if completeLine then
        return #line
      else
        return dialog.characterIndex
      end
    end)()),
      lineX,
      math.floor(lineY + (n - 1) * manager.lineHeight)
    )

    if manager.debug then
      love.graphics.setColor(colors.red)
      love.graphics.rectangle('line',
        lineX,
        math.floor(lineY + (n - 1) * manager.lineHeight),
        math.floor(manager.font:getWidth(line)),
        math.floor(manager.lineHeight)
      )
    end

    ::continue::
  end
end

local function drawImage(manager, dialog)
  if not dialog.image then return end

  love.graphics.setColor(colors.white)
  love.graphics.draw(dialog.image,
    manager.margin + manager.padding,
    dialog.y + manager.margin + manager.padding
  )
end

local printOptions = function (manager, dialog)
  local lineX = math.floor(manager.margin + manager.padding)
  if dialog.image then
    lineX = lineX + dialog.image:getWidth() + manager.padding
  end
  if dialog.options and (#dialog.optionLabels > 0) then
    local optionsY = dialog.y + dialog.height - manager.margin - manager.padding - dialog.optionsH
    for m = 1, #dialog.optionLabels do
      local label = dialog.optionLabels[m]

      love.graphics.setColor(colors.gray)
      if label == dialog.selectedOption then
        love.graphics.setColor(colors.green)
      end

      love.graphics.print(label, lineX, math.floor(optionsY + (m - 1) * manager.lineHeight) + manager.optionsSeparation)
    end
  end
end

-- ############################################################

local defaultFont = love.graphics.newFont()
defaultFont = love.graphics.newFont(defaultFont:getBaseline() * 1.5)
local defaultLineSpacing = 1.4
local dialove = {
  activeDialog = nil,
  activeDialogListIndex = 1,
  activeDialogListMap = {},
  defaultNumberOfLines = 4,
  bgColor = colors.alphaBlack,
  fgColor = colors.white,
  margin = 8,
  cornerRadius = 7,
  viewportW = love.graphics.getWidth(),
  viewportH = love.graphics.getHeight(),
  debug = false,
  speedFactor = 1,
  normalCharacterDelay = 0.03,
  delayPerCharacerMap = {
    ['.'] = 0.6,
    ['?'] = 0.6,
    ['!'] = 0.6,
    [':'] = 0.6,
    [';'] = 0.6,
    [','] = 0.35
  },
  -- ugly hack, I need help on this:
  typingSound = love.audio.newSource((...):sub(1, #(...) - 7) .. '/assets/typing-sound.ogg', 'static')
}
dialove.__index = dialove

dialove.init = function (data)
  local d = {}
  
  dialove.font = data.font or defaultFont
  dialove.viewportW = data.viewportW or dialove.viewportW
  dialove.viewportH = data.viewportH or dialove.viewportH
  dialove.margin = data.margin or dialove.margin
  dialove.cornerRadius = data.cornerRadius or dialove.cornerRadius
  dialove.lineHeight = dialove.font:getHeight() * (data.lineSpacing or defaultLineSpacing)
  dialove.padding = data.padding or math.floor(dialove.font:getHeight())
  dialove.cornerRadius = data.cornerRadius or dialove.cornerRadius
  dialove.optionsSeparation = data.optionsSeparation or dialove.lineHeight
  dialove.defaultNumberOfLines = data.numberOfLines or dialove.defaultNumberOfLines

  dialove.fontH = dialove.font:getHeight()
  dialove.typingSound:setVolume(data.typingVolume or 1)

  return setmetatable(d, dialove)
end

function dialove:setDebug(value)
  self.debug = value
end

function dialove:getActiveDialog()
  return self.activeDialog
end

function dialove:setActiveDialog(dialog)
  self.activeDialog = dialog
end

function dialove:getActiveDialogList()
  return self.activeDialogListMap[self.activeDialogListIndex]
end

function dialove:setActiveDialogList(obj)
  self.activeDialogListMap[self.activeDialogListIndex] = obj
end

function dialove:changeOption(sense)
  if not self:getActiveDialog().options or
  not self:getActiveDialog().done
  then
    return
  end

  local newIndex
  if sense > 0 then
    newIndex = self:getActiveDialog().selectedOptionIndex + 1
  elseif sense < 0 then
    newIndex = self:getActiveDialog().selectedOptionIndex - 1
  end

  if newIndex < 1 then newIndex = #self:getActiveDialog().optionLabels end
  if newIndex > #self:getActiveDialog().optionLabels then newIndex = 1 end

  self:setDialogOption(self:getActiveDialog(), newIndex)
end

function dialove:setDialogOption(dialog, index)
  dialog.selectedOptionIndex = index
  dialog.selectedOption = dialog.optionLabels[index]
end

function dialove:initOptions(dialog)
  local optionsH = 0
  if not dialog.options then return optionsH end
  
  dialog.optionLabels = {}
  for i, actionItem in ipairs(dialog.options) do
    actionItem.action = actionItem[2]
    table.insert(dialog.optionLabels, actionItem[1] or ('<option ' .. i .. '>'))
  end

  dialog.executeAction = function (action)
    self.activeDialogListIndex = self.activeDialogListIndex + 1
    self.activeDialog = nil
    action()
  end

  self:setDialogOption(dialog, 1)

  if dialog.options and (#dialog.optionLabels > 0) then
    optionsH = (#dialog.optionLabels - 1) * self.lineHeight + self.font:getHeight() + self.optionsSeparation
    dialog.needsInput = true
  end

  return optionsH
end

function dialove:initBounds(dialog, optionsH)
  dialog.optionsH = optionsH
  dialog.backgroundH = (dialog.linesH) + self.padding * 2 + dialog.optionsH

  if optionsH == 0 then
    dialog.backgroundH = dialog.backgroundH - (self.lineHeight - self.font:getHeight())
  end

  local heightToFitImage = 0
  if dialog.image then
    heightToFitImage = dialog.image:getHeight() + self.padding * 2
    if heightToFitImage > dialog.backgroundH then
      dialog.backgroundH = heightToFitImage
    end
  end

  dialog.height = dialog.backgroundH + self.margin * 2
  dialog.y = self.viewportH - dialog.height

  if dialog.top then
    dialog.y = 0
  elseif dialog.middle then
    dialog.y = self.viewportH / 2 - dialog.height / 2
  end
end

function dialove:show(data)
  self:push(data)
  self:pop(true)
end

function dialove:push(data)
  local newDialog = {
    characterIndex = 0,
    lineIndex = 1,
    lines = {},
    done = false
  }

  local content = data
  
  if type(data) == 'table' then
    content = data.text or ''
    
    newDialog.title = data.title
    newDialog.numberOfLines = data.numberOfLines or self.defaultNumberOfLines
    newDialog.autoHeight = data.autoHeight
    newDialog.top = (data.position == 'top')
    newDialog.middle = (data.position == 'middle') -- has priority over 'top'
    newDialog.options = data.options
    newDialog.image = data.image

    if newDialog.options and not (type(newDialog.options) == 'table') then
      error('options value must be a list of strings')
    end
  end
  
  local currentLine = ''
  local lineWasInserted = false

  local wordsToInsert = {}
  for word in string.gmatch(content, '([^( |\n)]+)') do
    table.insert(wordsToInsert, word)
  end

  local indexWord = 1

  newDialog.noPaddingWidth = self.viewportW - (self.padding * 2 + self.margin * 2)
  if newDialog.image then
    newDialog.noPaddingWidth = newDialog.noPaddingWidth - (newDialog.image:getWidth() + self.padding)
  end

  -- this is the magic
  for _, word in ipairs(wordsToInsert) do
    local currentLineBkp = currentLine
    currentLine = currentLine .. word .. ' '
    lineWasInserted = false

    if self.font:getWidth(currentLineBkp .. word) >= newDialog.noPaddingWidth then
      --[[
        -1 removes the trailing space:
      ]]
      table.insert(newDialog.lines, currentLineBkp:sub(1, #currentLineBkp - 1))
      indexWord = indexWord + 1
      currentLine = word .. ' '
      currentLineBkp = ''
      lineWasInserted = true
    end
  end

  -- just one line that doesn't fill the width
  if not lineWasInserted or indexWord < #wordsToInsert then
    --[[
      -1 removes the trailing space:
    ]]
    currentLine = currentLine:sub(1, #currentLine - 1)
    table.insert(newDialog.lines, currentLine)
  end

  local numberOfLines = newDialog.numberOfLines or self.defaultNumberOfLines
  if newDialog.autoHeight then
    numberOfLines = #newDialog.lines
  end

  newDialog.linesH = numberOfLines * self.lineHeight
  local optionsH = self:initOptions(newDialog)
  self:initBounds(newDialog, optionsH)

  if not self:getActiveDialogList() then
    self:setActiveDialogList({})
  end

  table.insert(self:getActiveDialogList(), newDialog)
end

function dialove:pop(forcePop)
  if forcePop then goto tryPop end

  if self:getActiveDialog() then
    if not self:getActiveDialog().done then
      return
    end

    if self:getActiveDialog().needsInput then
      local action = self:getActiveDialog().options[self:getActiveDialog().selectedOptionIndex].action
      self:getActiveDialog().executeAction(action)
      return
    end
  end

  ::tryPop::

  if self:getActiveDialogList() and #self:getActiveDialogList() > 0 then
    local dialogPopped = table.remove(self:getActiveDialogList(), 1)
    self:setActiveDialog(dialogPopped)
    timer.new('showNextCharacter', self.normalCharacterDelay)
  else
    self:setActiveDialog(nil)
    repeat
      if self.activeDialogListIndex >= 1 then
        self.activeDialogListIndex = self.activeDialogListIndex - 1
        table.remove(self.activeDialogListMap)
      end
    until not self:getActiveDialogList() or #self:getActiveDialogList() > 0

    if self:getActiveDialogList() then
      local dialogPopped = table.remove(self:getActiveDialogList(), 1)
      self:setActiveDialog(dialogPopped)
    end
  end
end

function dialove:playTypingSound(currentChar, dialog)
  if (not self.delayPerCharacerMap[currentChar]) and (dialog.lineIndex <= #dialog.lines) then
    love.audio.play(self.typingSound)
  end
end

function dialove:getDelayForCharacter(char)
  local delay = (self.delayPerCharacerMap[char] or self.normalCharacterDelay)
  return delay / self.speedFactor
end

function dialove:faster() self.speedFactor = 4 end
function dialove:slower() self.speedFactor = 1 end

function dialove:update(dt)
  local dialog = self:getActiveDialog()
  
  if (not dialog) or dialog.done then
    return
  end

  if timer.isTimeTo('showNextCharacter', dt) then
    local currentLine = dialog.lines[dialog.lineIndex]
    timer.new('showNextCharacter', self.normalCharacterDelay)
    dialog.characterIndex = dialog.characterIndex + 1

    local currentChar = currentLine:sub(dialog.characterIndex, dialog.characterIndex)
    local newDelayForCharacter = self:getDelayForCharacter(currentChar)
    timer.setDelay('showNextCharacter', newDelayForCharacter)
    
    if dialog.characterIndex > #currentLine then
      dialog.lineIndex = dialog.lineIndex + 1
      dialog.characterIndex = 1
      
      if dialog.lineIndex > #dialog.lines then
        dialog.done = true
      end
    end
    self:playTypingSound(currentChar, dialog)
  end
end

function dialove:complete()
  if self:getActiveDialog() then
    local d = self:getActiveDialog()
    local lines = d.lines
    
    d.lineIndex = #d.lines
    d.characterIndex = #d.lines[d.lineIndex]
    timer.completeIteration('showNextCharacter')
  end
end

function dialove:draw()
  love.graphics.push('all')
  love.graphics.setFont(self.font)
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle('smooth')

  local dialog = self:getActiveDialog()
  if not dialog then
    love.graphics.pop()
    return
  end

  drawBackground(self, dialog)

  printTitle(self, dialog)
  -- lines already spelled:
  printText(self, dialog, 1, dialog.lineIndex - 1, true)
  -- line currently being spelled::
  printText(self, dialog, dialog.lineIndex, dialog.lineIndex, false)
  drawImage(self, dialog)
  if dialog.done then
    printOptions(self, dialog)
  end
  love.graphics.pop()
end

return dialove
