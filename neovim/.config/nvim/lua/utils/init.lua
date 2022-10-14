local M = {}

function M.t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function M.log(msg, hl, name)
  name = name or "Neovim"
  hl = hl or "Todo"
  vim.api.nvim_echo({ { name .. ": ", hl }, { msg } }, true, {})
end

function M.warn(msg, name)
  vim.notify(msg, vim.log.levels.WARN, { 
    title = name,
    timeout = 1500 
  })
end

function M.error(msg, name)
  vim.notify(msg, vim.log.levels.ERROR, { 
    title = name,
    timeout = 1500 
  })
end

function M.info(msg, name)
  vim.notify(msg, vim.log.levels.INFO, { 
    title = name,
    timeout = 1500 
  })
end

return M
