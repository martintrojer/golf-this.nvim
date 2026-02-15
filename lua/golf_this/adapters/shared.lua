local M = {}

function M.get_api_key(cfg)
  -- If someone accidentally puts a raw key into api_key_env, accept it as a direct key.
  if type(cfg.api_key_env) == "string" and cfg.api_key_env:match("^sk%-") then
    return cfg.api_key_env, nil
  end

  if cfg.api_key_env and cfg.api_key_env ~= "" then
    local key = vim.env[cfg.api_key_env]
    return key, cfg.api_key_env
  end

  if cfg.api_key and cfg.api_key ~= "" then
    local from_env = vim.env[cfg.api_key]
    if from_env and from_env ~= "" then
      return from_env, cfg.api_key
    end
    return cfg.api_key, nil
  end

  return nil, nil
end

function M.system_prompt()
  return table.concat({
    "You are a Vim golf assistant.",
    "Return ONLY valid JSON with keys: explanation (string), steps (array of strings), keys (string).",
    "explanation must be short (<= 2 sentences).",
    "steps must be concise and actionable.",
    "keys must be a single normal-mode keystroke sequence for nvim_feedkeys.",
    "Prefer robust motions/text-objects over line numbers when possible.",
    "If unsafe or unknown, return empty keys and explain.",
  }, " ")
end

function M.build_user_message(prompt, request)
  local lines = {
    "Task:",
    prompt,
    "",
    string.format("Current cursor line (%d):", request.current_row),
    request.current_line,
    "",
  }

  if request.selection then
    table.insert(lines, string.format("Selected lines (%d-%d):", request.selection.start_line, request.selection.end_line))
    table.insert(lines, request.selection.text)
    table.insert(lines, "")
  end

  table.insert(lines, "Current buffer excerpt:")
  table.insert(lines, request.buffer_excerpt)

  return table.concat(lines, "\n")
end

function M.decode_response_json(response_body)
  local ok, parsed = pcall(vim.json.decode, response_body)
  if not ok or not parsed then
    return nil, "failed to parse model response"
  end
  return parsed, nil
end

return M
