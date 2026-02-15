local shared = require("golf_this.adapters.shared")

local M = {}

local function extract_content(parsed)
  local content = (((parsed or {}).choices or {})[1] or {}).message
  content = content and content.content or nil

  if type(content) == "string" then
    return content
  end

  if type(content) == "table" then
    local chunks = {}
    for _, block in ipairs(content) do
      if type(block) == "table" and block.type == "text" and type(block.text) == "string" then
        table.insert(chunks, block.text)
      end
    end
    if #chunks > 0 then
      return table.concat(chunks, "\n")
    end
  end

  return nil
end

function M.new(cfg)
  local api_key, api_key_env = shared.get_api_key(cfg)

  return {
    kind = "openai_compatible",
    validate = function()
      if api_key_env and (not api_key or api_key == "") then
        return string.format("missing API key: set $%s", api_key_env)
      end
      return nil
    end,
    build_request = function(prompt, request)
      local headers = {
        ["Content-Type"] = "application/json",
      }

      if api_key and api_key ~= "" then
        headers.Authorization = "Bearer " .. api_key
      end

      if cfg.referer and cfg.referer ~= "" then
        headers["HTTP-Referer"] = cfg.referer
      end

      if cfg.title and cfg.title ~= "" then
        headers["X-Title"] = cfg.title
      end

      local payload = {
        model = cfg.model,
        temperature = 0,
        messages = {
          { role = "system", content = shared.system_prompt() },
          { role = "user", content = shared.build_user_message(prompt, request) },
        },
      }

      return {
        method = "POST",
        url = cfg.url,
        headers = headers,
        body = vim.json.encode(payload),
      }
    end,
    parse_response = function(response_body)
      local parsed, decode_err = shared.decode_response_json(response_body)
      if decode_err then
        return nil, decode_err
      end

      local content = extract_content(parsed)
      if type(content) ~= "string" then
        return nil, "missing response content"
      end

      return content, nil
    end,
  }
end

return M
