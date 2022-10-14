local M = {}

function M.setup()
  local coq = require "coq"
  -- Initialize Coq
  coq.Now() 

  -- 3p sources
  require "coq_3p" {
    -- Lua
    { src = "nvimlua", short_name = "nLUA", conf_only = false },
    -- Calculator
    { src = "bc", short_name = "MATH", precision = 6 },
    {
      src = "repl",
      sh = "bash",
      shell = { p = "perl", n = "node" },
      max_lines = 99,
      deadline = 500,
      unsafe = { "rm", "poweroff", "mv" },
    },
  }
end

return M
