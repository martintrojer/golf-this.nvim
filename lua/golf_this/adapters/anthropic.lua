local shared = require("golf_this.adapters.shared")

local M = {}

local function extract_content(parsed)
  if type(parsed) ~= "table" or type(parsed.content) ~= "table" then
    return nil
  end

  local chunks = {}
  for _, block in ipairs(parsed.content) do
    if type(block) == "table" and block.type == "text" and type(block.text) == "string" then
      table.insert(chunks, block.text)
    end
  end

  if #chunks == 0 then
    return nil
  end

  return table.concat(chunks, "\n")
end

function M.new(cfg)
  local api_key, api_key_env = shared.get_api_key(cfg)

  return {
    kind = "anthropic",
    validate = function()
      if api_key_env and (not api_key or api_key == "") then
        return string.format("missing API key: set $%s", api_key_env)
      end
      return nil
    end,
    build_request = function(prompt, request)
      local headers = {
        ["Content-Type"] = "application/json",
        ["anthropic-version"] = cfg.anthropic_version or "2023-06-01",
      }

      if api_key and api_key ~= "" then
        headers["x-api-key"] = api_key
      end

      local payload = {
        model = cfg.model,
        max_tokens = cfg.max_tokens or 600,
        system = shared.system_prompt(),
        messages = {
          {
            role = "user",
            content = shared.build_user_message(prompt, request),
          },
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
