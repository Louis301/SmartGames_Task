
-- для рандомизации пермешивания ячеек
math.randomseed(os.time())

-- базовый класс игры
local Game = {}
Game.__index = Game

-- параметры игрового поля
local COLORS = {'A', 'B', 'C', 'D', 'E', 'F'}
local SIZE = 10


-------------------------------------------------- // инициализация игрового поля
function Game:init()
  -- Инициализация случайными цветами --
  self.field = {}           
  for y = 1, SIZE do
     self.field[y] = {}
     for x = 1, SIZE do
       self.field[y][x] = COLORS[math.random(#COLORS)]
     end
  end

-- Статическая инициализация по ТЗ --
-- self.field = {
--   {'A','B','C','D','E','F','A','B','C','D'},
--   {'B','A','B','C','D','E','F','A','B','C'},
--   {'A','B','C','D','E','F','A','B','C','D'},
--   {'B','A','B','C','D','E','F','A','B','C'},
--   {'A','B','C','D','E','F','A','B','C','D'},
--   {'B','A','B','C','D','E','F','A','B','C'},
--   {'A','B','C','D','E','F','A','B','C','D'},
--   {'B','A','B','C','D','E','F','A','B','C'},
--   {'A','B','C','D','E','F','A','B','C','D'},
--   {'B','A','B','C','D','E','F','A','B','C'}
-- }

  -- проверка наличия тройки при генерации
  while self:_has_any_match() do
    self:mix()
  end
end


-------------------------------------------------- // вывод игрового поля
function Game:dump()
  io.write("    ")
  for x = 0, SIZE - 1 do
    io.write(string.format("%s ", x))
  end
  io.write("\n")
  io.write("   ")
  for _ = 1, SIZE * 2 do io.write("-") end
  io.write("\n")

  for y = 1, SIZE do
    io.write(string.format("%d |", y - 1))
    for x = 1, SIZE do
      io.write(" " .. self.field[y][x])
    end
    io.write("\n")
  end
  io.write("\n")
end


-------------------------------------------------- // обработка хода игрока
function Game:move(x1, y1, x2, y2)
  local r1, c1 = y1 + 1, x1 + 1
  local r2, c2 = y2 + 1, x2 + 1

  -- проверка вхождения в поле
  if not (r1 >= 1 and r1 <= SIZE and c1 >= 1 and c1 <= SIZE and r2 >= 1 and r2 <= SIZE and c2 >= 1 and c2 <= SIZE) then
    return false
  end

  -- проверка соседних клеток
  local dr = math.abs(r1 - r2)
  local dc = math.abs(c1 - c2)
  if not ((dr == 1 and dc == 0) or (dr == 0 and dc == 1)) then
    return false
  end

  -- обмен ячейками
  self.field[r1][c1], self.field[r2][c2] = self.field[r2][c2], self.field[r1][c1]

  -- проверка наличилия тройки, иначе - откат хода
  if self:_has_any_match() then
    return true
  else
    self.field[r1][c1], self.field[r2][c2] = self.field[r2][c2], self.field[r1][c1]
    return false
  end
end


-------------------------------------------------- // выполнение "тика"
function Game:tick()
  local matches = self:_find_all_matches()
  if #matches == 0 then
    return false
  end
  -- удаление совпадающих ячеек
  local to_remove = {}
  for y = 1, SIZE do
    to_remove[y] = {}
    for x = 1, SIZE do
      to_remove[y][x] = false
    end
  end

  for _, group in ipairs(matches) do
    for _, pos in ipairs(group) do
      to_remove[pos.y][pos.x] = true
    end
  end
  -- сдвиг столбцов вниз
  for x = 1, SIZE do
    local write_pos = SIZE
    for y = SIZE, 1, -1 do
      if not to_remove[y][x] then
        self.field[write_pos][x] = self.field[y][x]
        write_pos = write_pos - 1
      end
    end
    -- заполнение новыми камнями
    while write_pos >= 1 do
      self.field[write_pos][x] = COLORS[math.random(#COLORS)]
      write_pos = write_pos - 1
    end
  end
  return true
end


-------------------------------------------------- // рандомизация ячеек поля (предупреждение троек)
function Game:mix()
  repeat
    for y = 1, SIZE do
      for x = 1, SIZE do
        self.field[y][x] = COLORS[math.random(#COLORS)]
      end
    end
  until not self:_has_any_match()
end


-------------------------------------------------- // (служебная) находит все группы совпадений (минимум 3 подряд)
function Game:_find_all_matches()
  local matches = {}

  -- по горизонтали
  for y = 1, SIZE do
    local count = 1
    local current = self.field[y][1]
    local start_x = 1
    for x = 2, SIZE do
      if self.field[y][x] == current then
        count = count + 1
      else
        if count >= 3 then
          local group = {}
          for i = 0, count - 1 do
            table.insert(group, {x = start_x + i, y = y})
          end
          table.insert(matches, group)
        end
        current = self.field[y][x]
        count = 1
        start_x = x
      end
    end
    if count >= 3 then
      local group = {}
      for i = 0, count - 1 do
        table.insert(group, {x = start_x + i, y = y})
      end
      table.insert(matches, group)
    end
  end

  -- по вертикали
  for x = 1, SIZE do
    local count = 1
    local current = self.field[1][x]
    local start_y = 1
    for y = 2, SIZE do
      if self.field[y][x] == current then
        count = count + 1
      else
        if count >= 3 then
          local group = {}
          for i = 0, count - 1 do
            table.insert(group, {x = x, y = start_y + i})
          end
          table.insert(matches, group)
        end
        current = self.field[y][x]
        count = 1
        start_y = y
      end
    end
    if count >= 3 then
      local group = {}
      for i = 0, count - 1 do
        table.insert(group, {x = x, y = start_y + i})
      end
      table.insert(matches, group)
    end
  end

  return matches
end

-- проверка хотя бы одной тройки
function Game:_has_any_match()
  return #self:_find_all_matches() > 0
end

-- проверка валидности хода
function Game:_has_valid_move()
  -- проверка всех возможных обменов с соседями
  for y = 1, SIZE do
    for x = 1, SIZE do
      -- вправо
      if x < SIZE then
        local temp = self.field[y][x]
        self.field[y][x] = self.field[y][x+1]
        self.field[y][x+1] = temp
        if self:_has_any_match() then
          self.field[y][x+1] = self.field[y][x]
          self.field[y][x] = temp
          return true
        end
        self.field[y][x+1] = self.field[y][x]
        self.field[y][x] = temp
      end
      -- вниз
      if y < SIZE then
        local temp = self.field[y][x]
        self.field[y][x] = self.field[y+1][x]
        self.field[y+1][x] = temp
        if self:_has_any_match() then
          self.field[y+1][x] = self.field[y][x]
          self.field[y][x] = temp
          return true
        end
        self.field[y+1][x] = self.field[y][x]
        self.field[y][x] = temp
      end
    end
  end
  return false
end


-- ============================================================
-- MAIN
-- ============================================================
local game = setmetatable({}, Game)   -- инициализация экземпляра игры
game:init()

os.execute("cls")

while true do
  if not game:_has_valid_move() then
    game:mix()
  end

  game:dump()

  io.write("> ")
  local input = io.read("*line")
  print() 
  if not input or input == "q" then
    break
  end

  local cmd, x_str, y_str, dir = input:match("^%s*(%w+)%s+(%d+)%s+(%d+)%s+([lrud])%s*$")
  if cmd == "m" and x_str and y_str and dir then
    local x = tonumber(x_str)
    local y = tonumber(y_str)
    if x >= 0 and x < SIZE and y >= 0 and y < SIZE then
      local dx, dy = 0, 0

      if dir == "l" then dx = -1
      elseif dir == "r" then dx = 1
      elseif dir == "u" then dy = -1
      elseif dir == "d" then dy = 1
      end

      local x2, y2 = x + dx, y + dy
      if x2 >= 0 and x2 < SIZE and y2 >= 0 and y2 < SIZE then
        if game:move(x, y, x2, y2) then
          while game:tick() do
            --game:dump()
          end
        else
          print("The move is unacceptable (does not create a triple)\n")
        end
      else
        print("you can't move it outside the field\n")
      end
    else
      print("coords is out on diapose (0-9)\n")
    end
  else
    print("cmd is whong...\n")
  end
end