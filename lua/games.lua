
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

-- DOOM (:Doom)
-- Controls:
--   Movement: Arrow keys (Shift to run)
--   Turn: Left/Right arrows (Shift to quick-turn)
--   Strafe: Alt + Left/Right arrows (may not work in all terminals)
--   Fire: X
--   Use/Open doors: Space
--   Weapon selection: Number keys 0-8
--   Toggle automap: Tab
--   Menu: Escape
--   Select menu option: Enter
--   Toggle renderer: Ctrl+K (cycle kitty graphics and cell-based rendering)
--   Return control to Nvim: Ctrl+\ Ctrl+N

