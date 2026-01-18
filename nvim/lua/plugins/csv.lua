return {
  "chrisbra/csv.vim",
  config = function()
    local colors = {
      "#E06C75", -- 赤
      "#98C379", -- 緑
      "#61AFEF", -- 青
      "#E5C07B", -- 黄
    }

    local function apply_csv_colors()
      vim.api.nvim_set_hl(0, "CSVColumnOdd", { fg = colors[1] })
      vim.api.nvim_set_hl(0, "CSVColumnEven", { fg = colors[2] })
      vim.api.nvim_set_hl(0, "CSVColumnHeaderOdd", { fg = colors[3], bold = true })
      vim.api.nvim_set_hl(0, "CSVColumnHeaderEven", { fg = colors[4], bold = true })
    end

    apply_csv_colors()
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = apply_csv_colors,
    })
  end,
}
