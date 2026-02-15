local openai_compatible = require("golf_this.adapters.openai_compatible")
local anthropic = require("golf_this.adapters.anthropic")

local M = {}

function M.resolve(cfg)
  local kind = cfg.kind or "openai_compatible"

  if kind == "anthropic" then
    return anthropic.new(cfg), nil
  end

  if kind == "openai_compatible" then
    return openai_compatible.new(cfg), nil
  end

  return nil, "unsupported provider kind: " .. tostring(kind)
end

return M
