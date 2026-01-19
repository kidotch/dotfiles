-- Key mappings (centralized)

vim.keymap.set("n", "<leader>ub", function()
  _G.toggle_transparency()
end, { silent = true, desc = "UI: Toggle background transparency" })
vim.keymap.set("n", "<leader>un", function()
  _G.cycle_colorscheme_next()
end, { silent = true, desc = "UI: Next colorscheme" })
vim.keymap.set("n", "<leader>up", function()
  _G.cycle_colorscheme_prev()
end, { silent = true, desc = "UI: Prev colorscheme" })

-- F13 を Esc として使う
vim.keymap.set({ "n", "i", "v", "s" }, "<F12>", "<Esc>", { silent = true })

-- nvim-tree
vim.keymap.set("n", "<leader>tt", "<cmd>NvimTreeToggle<CR>", { desc = "Tree: Toggle" })
vim.keymap.set("n", "<leader>tF", "<cmd>NvimTreeFocus<CR>", { desc = "Tree: Focus" })
vim.keymap.set("n", "<leader>tf", "<cmd>NvimTreeFindFile<CR>", { desc = "Tree: Find file" })
vim.keymap.set("n", "<leader>tr", "<cmd>NvimTreeRefresh<CR>", { desc = "Tree: Refresh" })
vim.keymap.set("n", "<leader>tc", "<cmd>NvimTreeCollapse<CR>", { desc = "Tree: Collapse" })
vim.keymap.set("n", "<leader>to", "<cmd>NvimTreeOpen<CR>", { desc = "Tree: Open" })
vim.keymap.set("n", "<leader>tq", "<cmd>NvimTreeClose<CR>", { desc = "Tree: Close" })

-- Window resize (Alt+h/l)
vim.keymap.set("n", "<M-h>", "<cmd>vertical resize -2<CR>", { desc = "Window: Shrink width" })
vim.keymap.set("n", "<M-l>", "<cmd>vertical resize +2<CR>", { desc = "Window: Grow width" })

-- Copilot
vim.keymap.set("i", "<Tab>", function()
  local ok, suggestion = pcall(require, "copilot.suggestion")
  if ok and suggestion.is_visible() then
    suggestion.accept()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
  end
end, { desc = "Copilot: Accept suggestion or Tab" })

-- CSV: cell/quote operations
local function get_csv_cell_range()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local cell_start = 1
  local cell_end = #line
  local in_quote = false

  for i = 1, col do
    local c = line:sub(i, i)
    if c == '"' then in_quote = not in_quote end
    if c == "," and not in_quote and i < col then
      cell_start = i + 1
    end
  end

  in_quote = false
  for i = 1, #line do
    local c = line:sub(i, i)
    if c == '"' then in_quote = not in_quote end
    if c == "," and not in_quote and i >= col then
      cell_end = i - 1
      break
    end
  end

  return cell_start, cell_end
end

local function get_csv_quoted_range()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local in_quote = false
  local start = nil
  local i = 1

  while i <= #line do
    local c = line:sub(i, i)
    local nextc = line:sub(i + 1, i + 1)
    if c == '"' then
      if in_quote and nextc == '"' then
        i = i + 2
        goto continue
      end
      if not in_quote then
        in_quote = true
        start = i
      else
        local finish = i
        if col >= start and col <= finish then
          return start, finish
        end
        in_quote = false
        start = nil
      end
    end
    i = i + 1
    ::continue::
  end

  return nil, nil
end

local function get_csv_cell_range_by_index(index)
  local line = vim.api.nvim_get_current_line()
  local in_quote = false
  local cell_start = 1
  local cell_index = 1

  for i = 1, #line + 1 do
    local c = line:sub(i, i)
    if c == '"' then
      in_quote = not in_quote
    end
    if (c == "," and not in_quote) or i == #line + 1 then
      local cell_end = i - 1
      if cell_index == index then
        return cell_start, cell_end
      end
      cell_index = cell_index + 1
      cell_start = i + 1
    end
  end

  return nil, nil
end

local function get_csv_quoted_range_by_cell_index(index)
  local line = vim.api.nvim_get_current_line()
  local cell_start, cell_end = get_csv_cell_range_by_index(index)
  if not cell_start then
    return nil, nil
  end

  local in_quote = false
  local start = nil
  local i = cell_start

  while i <= cell_end do
    local c = line:sub(i, i)
    local nextc = line:sub(i + 1, i + 1)
    if c == '"' then
      if in_quote and nextc == '"' then
        i = i + 2
        goto continue
      end
      if not in_quote then
        in_quote = true
        start = i
      else
        local finish = i
        return start, finish
      end
    end
    i = i + 1
    ::continue::
  end

  return nil, nil
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "csv",
  callback = function()
    -- セル削除 (dc)
    vim.keymap.set("n", "dc", function()
      local line = vim.api.nvim_get_current_line()
      local cell_start, cell_end = get_csv_cell_range()
      local before = line:sub(1, cell_start - 1)
      local after = line:sub(cell_end + 1)
      vim.api.nvim_set_current_line(before .. after)
      vim.fn.cursor(0, math.max(1, cell_start))
    end, { buffer = true, silent = true, desc = "Delete CSV cell" })

    -- セル置換 (rc)
    vim.keymap.set("n", "rc", function()
      local line = vim.api.nvim_get_current_line()
      local count = vim.v.count
      local cell_start, cell_end
      if count > 0 then
        cell_start, cell_end = get_csv_cell_range_by_index(count)
      else
        cell_start, cell_end = get_csv_cell_range()
      end
      if not cell_start then
        vim.notify("CSV cell index out of range", vim.log.levels.WARN)
        return
      end
      local paste = vim.fn.getreg("+"):gsub("\n", "")
      local before = line:sub(1, cell_start - 1)
      local after = line:sub(cell_end + 1)
      vim.api.nvim_set_current_line(before .. paste .. after)
      vim.fn.cursor(0, cell_start)
    end, { buffer = true, silent = true, desc = "Replace CSV cell" })

    -- セルヤンク (yc)
    vim.keymap.set("n", "yc", function()
      local line = vim.api.nvim_get_current_line()
      local cell_start, cell_end = get_csv_cell_range()
      local content = line:sub(cell_start, cell_end)
      vim.fn.setreg("+", content)
      vim.notify("Yanked: " .. content)
    end, { buffer = true, silent = true, desc = "Yank CSV cell" })

    -- クォート範囲削除 (dq)
    vim.keymap.set("n", "dq", function()
      local line = vim.api.nvim_get_current_line()
      local count = vim.v.count
      local qs, qe
      if count > 0 then
        qs, qe = get_csv_quoted_range_by_cell_index(count)
      else
        qs, qe = get_csv_quoted_range()
      end
      if not qs then
        vim.notify("No quoted range under cursor", vim.log.levels.WARN)
        return
      end
      local before = line:sub(1, qs - 1)
      local after = line:sub(qe + 1)
      vim.api.nvim_set_current_line(before .. after)
      vim.fn.cursor(0, math.max(1, qs))
    end, { buffer = true, silent = true, desc = "Delete quoted range" })

    -- クォート範囲ヤンク (yq)
    vim.keymap.set("n", "yq", function()
      local line = vim.api.nvim_get_current_line()
      local count = vim.v.count
      local qs, qe
      if count > 0 then
        qs, qe = get_csv_quoted_range_by_cell_index(count)
      else
        qs, qe = get_csv_quoted_range()
      end
      if not qs then
        vim.notify("No quoted range under cursor", vim.log.levels.WARN)
        return
      end
      local content = line:sub(qs + 1, qe - 1)
      content = content:gsub('""', '"')
      vim.fn.setreg("+", content)
      vim.notify("Yanked: " .. content)
    end, { buffer = true, silent = true, desc = "Yank quoted content" })

    -- クォート範囲置換 (rq)
    vim.keymap.set("n", "rq", function()
      local line = vim.api.nvim_get_current_line()
      local count = vim.v.count
      local qs, qe
      if count > 0 then
        qs, qe = get_csv_quoted_range_by_cell_index(count)
      else
        qs, qe = get_csv_quoted_range()
      end
      if not qs then
        vim.notify("No quoted range under cursor", vim.log.levels.WARN)
        return
      end
      local paste = vim.fn.getreg("+"):gsub("\n", "")
      paste = paste:gsub('"', '""')
      local before = line:sub(1, qs)
      local after = line:sub(qe)
      vim.api.nvim_set_current_line(before .. paste .. after)
      vim.fn.cursor(0, qs + 1)
    end, { buffer = true, silent = true, desc = "Replace quoted content" })

    -- セルをクォート (sc)
    vim.keymap.set("n", "sc", function()
      local line = vim.api.nvim_get_current_line()
      local cell_start, cell_end = get_csv_cell_range()
      local content = line:sub(cell_start, cell_end)
      if content:sub(1, 1) == '"' and content:sub(-1) == '"' then
        vim.notify("Cell already quoted")
        return
      end
      local escaped = content:gsub('"', '""')
      local before = line:sub(1, cell_start - 1)
      local after = line:sub(cell_end + 1)
      vim.api.nvim_set_current_line(before .. '"' .. escaped .. '"' .. after)
      vim.fn.cursor(0, cell_start + 1)
    end, { buffer = true, silent = true, desc = "Quote CSV cell" })
  end,
})
