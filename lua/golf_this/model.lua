local adapters = require("golf_this.adapters")
local transport = require("golf_this.transport")

local M = {}

local function decode_json(text)
	local ok, decoded = pcall(vim.json.decode, text)
	if ok and decoded then
		return decoded
	end

	local json_block = text:match("```json%s*(.-)%s*```")
	if json_block then
		local ok_block, parsed_block = pcall(vim.json.decode, json_block)
		if ok_block and parsed_block then
			return parsed_block
		end
	end

	local object = text:match("(%b{})")
	if object then
		local ok_object, parsed_object = pcall(vim.json.decode, object)
		if ok_object and parsed_object then
			return parsed_object
		end
	end

	return nil
end

local function parse_solution_text(text)
	local result = decode_json(text)
	if not result then
		return nil, "model did not return valid JSON contract"
	end

	return {
		explanation = result.explanation or "",
		steps = vim.tbl_islist(result.steps) and result.steps or {},
		keys = result.keys or "",
	},
		nil
end

function M.solve_async(cfg, prompt, request, cb)
	local adapter, resolve_err = adapters.resolve(cfg)
	if resolve_err then
		cb(nil, resolve_err)
		return nil
	end

	local validation_err = adapter.validate and adapter.validate() or nil
	if validation_err then
		cb(nil, validation_err)
		return nil
	end

	local req = adapter.build_request(prompt, request)

	return transport.send(req, function(response, request_err)
		if request_err then
			cb(nil, request_err)
			return
		end

		if response.status < 200 or response.status >= 300 then
			cb(nil, string.format("model request failed (%s): %s", response.status, response.body))
			return
		end

		local content, parse_err = adapter.parse_response(response.body)
		if parse_err then
			cb(nil, parse_err)
			return
		end

		local solved, contract_err = parse_solution_text(content)
		if contract_err then
			cb(nil, contract_err)
			return
		end

		cb(solved, nil)
	end)
end

return M
