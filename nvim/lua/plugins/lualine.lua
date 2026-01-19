return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      section_separators = { left = '', right = ''},
      component_separators = { left = '', right = ''},
      icons_enabled = true,
      globalstatus = true,
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff" },
      lualine_c = { "filename" },
      lualine_x = {
        "encoding",
        "fileformat",
        "filetype",
        function()
          local name = vim.g.colors_name or "default"
          return "CS:" .. name
        end,
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {{
        'filename',
	file_status = true, -- Displays file status (readonly status, modified status)
	path = 1, -- Show relative path
      }},
      lualine_x = { "location" },
      lualine_y = {},
      lualine_z = {},
    },
    tabline = {},
    extensions = { "quickfix", "nvim-tree" },
  },
}
