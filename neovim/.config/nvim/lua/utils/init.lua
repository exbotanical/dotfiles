local M = {}

function M.is_empty(s)
  return s == nil or s == ""
end

function M.get_buf_option(opt)
  local ok, buf_option = pcall(vim.api.nvim_buf_get_option, 0, opt)
  if not ok then
    return nil
  else
    return buf_option
  end
end

return M
