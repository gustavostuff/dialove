## Dialove, Dialog library for LÖVE

[![License](http://img.shields.io/:license-MIT-blue.svg)](https://github.com/tavuntu/dialove/blob/main/LICENSE.md)
[![Version](http://img.shields.io/:beta-0.0.1-green.svg)](https://github.com/tavuntu/dialove)

## Usage

```lua
local Dialove = require('Dialove')

function love.load()
  dialogManager = Dialove.init({
    font = love.graphics.newFont('your-font', 16)
  })
  dialogManager:push('Dialog content') -- stores a dialog into memory
  dialogManager:pop() -- requests the first pushed dialog to be shown on screen
  
  -- show() does both things, but don't do this:
  dialogManager:show('Dialog content')
  dialogManager:show('Dialog content')
  dialogManager:show('Dialog content') -- only this one will be shown

  -- use this approach instead:
  dialogManager:show('Dialog content')
  dialogManager:push('Dialog content')
  dialogManager:push('Dialog content')

end

function love.update(dt)
  dialogManager:update(dt)
end

function love.draw()
  dialogManager:draw()
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
end

function love.keyreleased(k)
  if k == 'space' then
    dialogManager:slower()
  end
end
```

## Screenshots

[![Screen-Shot-2020-12-28-at-9-30-26-PM.png](https://i.postimg.cc/FHgXncym/Screen-Shot-2020-12-28-at-9-30-26-PM.png)](https://postimg.cc/CR12RRr6)

Code:

```lua
dialogManager:show(randomText())
```

[![Screen-Shot-2020-12-28-at-9-30-38-PM.png](https://i.postimg.cc/kM050Qbt/Screen-Shot-2020-12-28-at-9-30-38-PM.png)](https://postimg.cc/6ThwRGz9)

Code:

```lua
dialogManager:show({text = randomText(), title = 'The title'})
```

[![Screen-Shot-2020-12-28-at-9-30-50-PM.png](https://i.postimg.cc/DwFwZ75v/Screen-Shot-2020-12-28-at-9-30-50-PM.png)](https://postimg.cc/4mLg2krq)

Code:

```lua
dialogManager:show({
  text = randomText(),
  title = 'The title',
  options = {
    { 'Option 1', function () --[[ do stuff ]] end },
    { 'Option 2', function () --[[ do stuff ]] end }
  },
  position = 'top'
})
```

[![Screen-Shot-2020-12-28-at-9-31-04-PM.png](https://i.postimg.cc/fLdGm9T6/Screen-Shot-2020-12-28-at-9-31-04-PM.png)](https://postimg.cc/ZBTsh0Nc)

Code:

```lua
dialogManager:show({
  text = randomText(),
  title = 'The title',
  options = {
    { 'Option 1', function () --[[ do stuff ]] end },
    { 'Option 2', function () --[[ do stuff ]] end }
  },
  image = love.graphics.newImage('face.png'),
  position = 'middle'
})
```

Dialove supports a Tree/List like structure for dialog flows. Consider this:

[![dialove-flow.png](https://i.postimg.cc/XJ8FDZpP/dialove-flow.png)](https://postimg.cc/ygDkD8hh)

This may be specially useful for RPG games or any game where the story can have a lot of different paths. The code equivalent would be something like:

```lua
dialogManager:show({text = 'Dialog 1', options = {
  {
    'Choose Dialog 2', function ()
      dialogManager:show('Dialog 2')
      dialogManager:push('Dialog 4')
    end
  },
  {
    'Choose Dialog 3', function ()
      dialogManager:show({text = 'Dialog 3', options = {
        {
          'Choose Dialog 5', function ()
            dialogManager:show('Dialog 5')
          end
        },
        {
          'Choose Dialog 6', function ()
            dialogManager:show('Dialog 6')
          end
        }
      }})
    end
  }
}})

dialogManager:push('Dialog 7')

dialogManager:push({text = 'Dialog 8', options = {
  {
    'Choose Dialog 9', function ()
      dialogManager:show('Dialog 9')
      dialogManager:push('Dialog 10')
      dialogManager:push('Dialog 11')
      dialogManager:push('Dialog 12')
    end
  },
  {
    'Choose Dialog 13', function ()
      dialogManager:show('Dialog 13')
      dialogManager:push({
        text = 'Dialog 14',
        image = love.graphics.newImage('face.png')
      })
    end
  }
}})
```

## API

<details>
  <summary>Dialove.init([table])</summary>
  
  ```table``` supports the properties:

  * ```font```: LÖVE [Font](https://love2d.org/wiki/Font)
    * The font to use
  * ```viewportW```: number
    * will normally be your canvas width
  * ```viewportH```: number
    * will normally be your canvas height
  * ```margin```: number
    * space between the screen edge and the dialog background
  * ```cornerRadius```: number
    * the radius of corners for color/texture backgrounds
  * ```lineSpacing```: number
    * defaults to 1.4
  * ```padding```: number
    * Space between text and the edge of the dialog background
  * ```optionsSeparation```: number
    * Force the space between the last line of text and the options (pixels)
  * ```defaultNumberOfLines```: number
    * number of lines used for all dialogs (not inclusing the line(s) for the options)
  * ```typingSound```: LÖVE [Source](https://love2d.org/wiki/Source)
    * Typing sound (ignored for spaces)
</details>

<details>
  <summary>dialogManager.dialog([text|table])</summary>
  
  ```table``` supports the properties:

  * ```text```: string
    * the content of the dialog
  * ```title```: string
    * usually the character name
  * ```numberOfLines```: number
    * same as in ```defaultNumberOfLines``` in ```Dialog.init()```, just at dialog level
  * ```autoHeight```: boolean
    * When true, the dialog height will fit all the text and or the image
  * ```position```: string
    * ```top``` or ```middle``` (defaults to a bottom position)
  * ```options```: table
    * A list of tables where each one is a string at index 1 and a function at index 2, as shown in the examples
  * ```image```: LÖVE [Image](https://love2d.org/wiki/Image)
    * usually the character face
</details>

---

**Please note: Dialove is still a WIP**

Features pending:

* Background colors
* Background textures
* Other things to make this more flexible


Anime girl face courtesy of [Annie Mei Project](https://www.pinterest.com.mx/SherGwang/annie-mei-project/)
