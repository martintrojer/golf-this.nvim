local adapters = require("promptly.adapters")
local config = require("promptly.config")
local shared = require("promptly.adapters.shared")
local transport = require("promptly.transport")

local M = {}

local function has_value(v)
	return type(v) == "string" and v ~= ""
end

local function status_line(ok, text)
	local icon = ok and "OK" or "FAIL"
	return string.format("[%s] %s", icon, text)
end

function M.check()
	local profile_name = config.current_profile_name()
	local profile = config.current_profile()
	local profile_err = config.current_profile_error()
	if profile_err then
		vim.notify("promptly health\n[FAIL] " .. profile_err, vim.log.levels.ERROR)
		return
	end
	local provider_name = profile and profile.provider or nil
	local provider = config.current_provider()

	if not provider then
		vim.notify("promptly health\n[FAIL] provider not found in setup()", vim.log.levels.ERROR)
		return
	end

	local lines = {
		"promptly health",
		string.format("profile: %s", tostring(profile_name)),
		string.format("provider: %s", tostring(provider_name)),
	}
	local has_failures = false

	local kind = provider.kind or "openai_compatible"
	local valid_kind = kind == "openai_compatible" or kind == "anthropic"
	table.insert(lines, status_line(valid_kind, "kind: " .. tostring(kind)))
	has_failures = has_failures or not valid_kind

	local has_url = has_value(provider.url)
	table.insert(lines, status_line(has_url, "url: " .. tostring(provider.url or "(missing)")))
	has_failures = has_failures or not has_url

	local has_model = has_value(provider.model)
	table.insert(lines, status_line(has_model, "model: " .. tostring(provider.model or "(missing)")))
	has_failures = has_failures or not has_model

	local api_key, api_key_env = shared.get_api_key(provider)
	if api_key_env then
		local key_ok = has_value(api_key)
		table.insert(lines, status_line(key_ok, "api key from $" .. api_key_env))
		has_failures = has_failures or not key_ok
	elseif has_value(provider.api_key) then
		table.insert(lines, status_line(true, "api key configured directly"))
	else
		table.insert(lines, status_line(true, "no api key configured (expected for local providers)"))
	end

	local adapter, adapter_err = adapters.resolve(provider)
	if adapter_err then
		table.insert(lines, status_line(false, adapter_err))
		vim.notify(table.concat(lines, "\n"), vim.log.levels.ERROR)
		return
	end

	local validation_err = adapter.validate and adapter.validate() or nil
	if validation_err then
		table.insert(lines, status_line(false, validation_err))
		has_failures = true
	else
		table.insert(lines, status_line(true, "adapter validation"))
	end

	if not has_url then
		vim.notify(table.concat(lines, "\n"), vim.log.levels.ERROR)
		return
	end

	vim.notify("promptly: running endpoint check...", vim.log.levels.INFO)

	transport.send({
		method = "GET",
		url = provider.url,
		headers = {
			Accept = "application/json",
		},
		timeout_ms = 8000,
	}, function(response, err)
		if err then
			table.insert(lines, status_line(false, "endpoint unreachable: " .. err))
			vim.notify(table.concat(lines, "\n"), vim.log.levels.ERROR)
			return
		end

		-- 2xx/3xx/4xx/5xx all prove network reachability; 0 means transport issue.
		local reachable = type(response.status) == "number" and response.status > 0
		table.insert(lines, status_line(reachable, "endpoint reachable (HTTP " .. tostring(response.status) .. ")"))
		has_failures = has_failures or not reachable

		local level = has_failures and vim.log.levels.WARN or vim.log.levels.INFO
		vim.notify(table.concat(lines, "\n"), level)
	end)
end

return M
