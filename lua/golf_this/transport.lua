local M = {}

local function parse_status_output(stdout)
  local body, status = stdout:match("^(.*)\n__HTTP_STATUS__:(%d%d%d)%s*$")
  if not status then
    return nil, nil
  end
  return body, tonumber(status)
end

function M.send(req, cb)
  local done = vim.schedule_wrap(cb)
  local state = "pending"

  local function finish(response, err)
    if state == "cancelled" then
      return
    end

    if err then
      state = "error"
      done(nil, err)
      return
    end

    state = "success"
    done(response, nil)
  end

  if vim.system then
    local cmd = {
      "curl",
      "-sS",
      "--retry",
      "2",
      "--retry-delay",
      "1",
      "--connect-timeout",
      "10",
      "-X",
      req.method or "POST",
    }

    if req.stream then
      table.insert(cmd, "-N")
    end

    for key, value in pairs(req.headers or {}) do
      table.insert(cmd, "-H")
      table.insert(cmd, string.format("%s: %s", key, value))
    end

    if req.body and req.body ~= "" then
      table.insert(cmd, "--data-binary")
      table.insert(cmd, req.body)
    end

    table.insert(cmd, req.url)
    table.insert(cmd, "-w")
    table.insert(cmd, "\n__HTTP_STATUS__:%{http_code}")

    state = "running"
    local proc = vim.system(cmd, { text = true }, function(obj)
      if obj.code ~= 0 then
        local stderr = obj.stderr and obj.stderr ~= "" and obj.stderr or tostring(obj.code)
        finish(nil, "request failed: " .. stderr)
        return
      end

      local stdout = obj.stdout or ""
      local body, status = parse_status_output(stdout)
      if not status then
        finish(nil, "request failed: missing HTTP status")
        return
      end

      finish({ status = status, body = body or "" }, nil)
    end)

    return {
      cancel = function()
        if state == "running" and proc and proc.kill then
          pcall(proc.kill, proc, 2)
          state = "cancelled"
          return true
        end
        return false
      end,
      status = function()
        return state
      end,
    }
  end

  local ok, curl = pcall(require, "plenary.curl")
  if not ok then
    finish(nil, "Neovim 0.10+ required for async requests (or install plenary fallback)")
    return {
      cancel = function()
        return false
      end,
      status = function()
        return state
      end,
    }
  end

  state = "running"
  local method = (req.method or "POST"):lower()
  local client = curl[method]
  if type(client) ~= "function" then
    finish(nil, "unsupported HTTP method: " .. tostring(req.method))
  else
    local response = client(req.url, {
      headers = req.headers,
      body = req.body,
      timeout = req.timeout_ms or 30000,
    })
    finish({ status = response.status, body = response.body or "" }, nil)
  end

  return {
    cancel = function()
      return false
    end,
    status = function()
      return state
    end,
  }
end

return M
