local M = {}

function M.setup()
  require("project_nvim").setup {}

  require("nvim-tree").setup {
    respect_buf_cwd = true,
    update_cwd = true,
    update_focused_file = {
      enable = true,
      update_cwd = true,
    },
  }

  require("telescope").load_extension "projects"
end

return M
