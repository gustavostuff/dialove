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

return timer
