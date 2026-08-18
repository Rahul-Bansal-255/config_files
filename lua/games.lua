
-- killersheep (:KillKillKill)
require("killersheep").setup {
  gore = true,           -- Enables/disables blood and gore.
  keymaps = {
    move_left = "h",     -- Keymap to move cannon to the left.
    move_right = "l",    -- Keymap to move cannon to the right.
    shoot = "<Space>",   -- Keymap to shoot the cannon.
  },
}

-- Minesweeper (:Nvimesweeper)
-- Controls:
--   Press ! to flag a square.
--   Press ? to mark a square for later.
--   Press <Space> or <RightMouse> to cycle between !, ? and unmarking a square.
--   Press <CR>, x or <LeftMouse> to reveal a square; just try not to step on a mine!

-- Suduku (:Suduku)
require("sudoku").setup({})

