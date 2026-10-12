local M = {}

local function notify(message)
  vim.notify(message, vim.log.levels.WARN, { title = "Git line history" })
end

local function parse_history(output)
  local entries, entry = {}, nil
  for _, line in ipairs(vim.split(output, "\n", { plain = true })) do
    -- Patch lines have a diff prefix, so they cannot be mistaken for this header.
    local hash, date, subject = line:match("^@@LINE_HISTORY@@(%x+)\t([^\t]+)\t(.*)$")
    if hash then
      local display = hash:sub(1, 8) .. "  " .. date .. "  " .. subject
      entry = {
        value = hash,
        display = display,
        ordinal = display,
        preview = { "commit " .. hash, "Date: " .. date, "", "    " .. subject, "" },
      }
      table.insert(entries, entry)
    elseif entry then
      table.insert(entry.preview, line)
    end
  end
  return entries
end

local function open_picker(entries, filename, line)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  require("telescope.pickers").new({}, {
    prompt_title = "Line history: " .. vim.fn.fnamemodify(filename, ":t") .. ":" .. line,
    finder = require("telescope.finders").new_table({
      results = entries,
      entry_maker = function(entry) return entry end,
    }),
    sorter = require("telescope.config").values.generic_sorter({}),
    previewer = require("telescope.previewers").new_buffer_previewer({
      title = "Commit subject / line changes",
      define_preview = function(self, entry)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.preview)
        require("telescope.previewers.utils").highlighter(self.state.bufnr, "git")
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      local function open_change()
        local entry = action_state.get_selected_entry()
        if not entry then return end
        actions.close(prompt_bufnr)
        vim.cmd("botright new")
        vim.bo.buftype = "nofile"
        vim.bo.bufhidden = "wipe"
        vim.bo.swapfile = false
        vim.api.nvim_buf_set_lines(0, 0, -1, false, entry.preview)
        vim.bo.filetype = "git"
        vim.bo.modifiable = false
        vim.bo.readonly = true
      end
      -- Never inherit checkout or file-opening actions from a Git picker.
      for _, name in ipairs({ "select_default", "select_horizontal", "select_vertical", "select_tab" }) do
        actions[name]:replace(open_change)
      end
      return true
    end,
  }):find()
end

function M.show()
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" or vim.bo[bufnr].buftype ~= "" or vim.fn.filereadable(filename) ~= 1 then
    notify("Open a Git-tracked file first.")
    return
  end
  if vim.bo[bufnr].modified then
    notify("Save and commit this file's changes first; line history uses HEAD line numbers.")
    return
  end
  if vim.fn.executable("git") ~= 1 then
    notify("Git is not installed.")
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local cwd = vim.fn.fnamemodify(filename, ":h")
  local path = "./" .. vim.fn.fnamemodify(filename, ":t")
  local function still_current()
    return vim.api.nvim_buf_is_valid(bufnr)
      and vim.api.nvim_get_current_buf() == bufnr
      and vim.api.nvim_buf_get_changedtick(bufnr) == tick
  end

  -- Check both staged and unstaged edits, without writing to the index or worktree.
  vim.system({ "git", "--literal-pathspecs", "diff", "--quiet", "--no-ext-diff", "--no-textconv", "HEAD", "--", path },
    { cwd = cwd, text = true }, vim.schedule_wrap(function(diff)
      if not still_current() then return end
      if diff.code ~= 0 then
        notify(diff.code == 1 and diff.stderr == ""
          and "Commit this file's changes first; line history uses HEAD line numbers."
          or "Cannot read HEAD for this file. Open a file in a repository with commits.")
        return
      end

      -- One Git traversal preserves historical line numbers (unlike show -L at each commit).
      vim.system({ "git", "--no-pager", "log", "--color=never", "--no-ext-diff", "--no-textconv",
        "--find-renames", "--format=@@LINE_HISTORY@@%H%x09%as%x09%s",
        "-L", string.format("%d,%d:%s", line, line, path), "HEAD" },
        { cwd = cwd, text = true }, vim.schedule_wrap(function(result)
          if not still_current() then return end
          if result.code ~= 0 then
            notify("Cannot trace this line in HEAD. Check that the file and line are committed.")
            return
          end
          local entries = parse_history(result.stdout)
          if #entries == 0 then
            notify("No committed history found for this line.")
            return
          end
          open_picker(entries, filename, line)
        end))
    end))
end

return M
