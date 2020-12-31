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

local BASE = (...):sub(1, #(...) - 7) .. '/'

local timer = require(BASE .. 'timer')
local utils = require(BASE .. 'dialove-utils')

local defaultFont = love.graphics.newFont()
defaultFont = love.graphics.newFont(defaultFont:getBaseline() * 1.5)
local defaultLineSpacing = 1.4
local dialove = {
  activeDialog = nil,
  activeDialogListIndex = 1,
  activeDialogListMap = {},
  defaultNumberOfLines = 4,
  bgColor = utils.colors.alphaBlack,
  fgColor = utils.colors.white,
  margin = 8,
  cornerRadius = 7,
  viewportW = love.graphics.getWidth(),
  viewportH = love.graphics.getHeight(),
  debug = false,
  speedFactor = 1,
  normalCharacterDelay = 0.03,
  delayPerCharacerMap = {
    ['.'] = 0.5,
    ['?'] = 0.5,
    ['!'] = 0.5,
    [':'] = 0.5,
    [';'] = 0.5,
    [','] = 0.3
  },
  typingSound = love.audio.newSource(BASE .. 'assets/typing-sound.ogg', 'static'),
  backgroundTypes = {
    normal = 1,
    tiled = 2,
    clamped = 3
  }
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
  dialove.verticalPadding = data.verticalPadding or dialove.padding
  dialove.horizontalPadding = data.horizontalPadding or dialove.padding
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
    optionsH = (#dialog.optionLabels - 1) * self.lineHeight + self.fontH + self.optionsSeparation
    dialog.needsInput = true
  end

  return optionsH
end

function dialove:initBounds(dialog, optionsH)
  dialog.optionsH = optionsH
  dialog.backgroundH = (dialog.linesH) + self.verticalPadding * 2 + dialog.optionsH

  if optionsH == 0 then
    dialog.backgroundH = dialog.backgroundH - (self.lineHeight - self.fontH)
  end

  local heightToFitImage = 0
  if dialog.image then
    heightToFitImage = dialog.image:getHeight() + self.verticalPadding * 2
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
    newDialog.background = data.background or {}
    newDialog.background.type = newDialog.background.type or self.backgroundTypes.normal
    newDialog.titleColor = data.titleColor or self.blue
    newDialog.textColor = data.textColor or self.white
    newDialog.selectedOptionColor = data.selectedOptionColor or self.blue
    newDialog.unselectedOptionColor = data.unselectedOptionColor or self.gray

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

  newDialog.noPaddingWidth = self.viewportW - (self.horizontalPadding * 2 + self.margin * 2)
  if newDialog.image then
    newDialog.noPaddingWidth = newDialog.noPaddingWidth - (newDialog.image:getWidth() + self.horizontalPadding)
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

  -- extra props
  newDialog.quadWidth = (self.viewportW - self.margin * 2) / 2
  newDialog.quadHeight = (newDialog.height - self.verticalPadding * 2) / 2
  newDialog.backgroundQuad = love.graphics.newQuad(0, 0,
    math.floor(newDialog.quadWidth + 10),
    math.floor(newDialog.quadHeight + 10),
    (function()
      return (newDialog.background and newDialog.background.image and newDialog.background.image:getWidth()) or 0
    end)(),
    (function()
      return (newDialog.background and newDialog.background.image and newDialog.background.image:getHeight()) or 0
    end)()
  )

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
  love.graphics.setLineWidth(2)
  love.graphics.setLineStyle('smooth')

  local dialog = self:getActiveDialog()
  if not dialog then
    love.graphics.pop()
    return
  end

  utils.drawBackground(self, dialog)

  utils.printTitle(self, dialog)
  -- lines already spelled:
  utils.printText(self, dialog, 1, dialog.lineIndex - 1, true)
  -- line currently being spelled::
  utils.printText(self, dialog, dialog.lineIndex, dialog.lineIndex, false)
  utils.drawImage(self, dialog)
  if dialog.done then
    utils.printOptions(self, dialog)
  end
  love.graphics.pop()
end

return dialove
