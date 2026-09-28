--!nocheck
-- Tiny assertion helpers shared by the tests.

local process = require("@lune/process")

local T = {}

local passed, failed = 0, 0
local failures = {}

function T.section(name: string)
	print(`\n== {name}`)
end

function T.check(name: string, condition: any, detail: any?)
	if condition then
		passed += 1
		print(`  ok    {name}`)
	else
		failed += 1
		local text = if detail ~= nil then `{name} ({tostring(detail)})` else name
		table.insert(failures, text)
		print(`  FAIL  {text}`)
	end
end

-- Runs the test body; any error fails the run straight away instead of leaving background loops running.
function T.run(body: () -> ())
	local ok, err = xpcall(body, debug.traceback)
	if not ok then
		failed += 1
		table.insert(failures, `crashed: {err}`)
		print(`\nFAIL  test crashed: {err}`)
	end
	T.finish()
end

function T.finish()
	print(`\n{passed} passed, {failed} failed`)
	for _, text in failures do
		print(`  FAIL  {text}`)
	end
	process.exit(if failed == 0 then 0 else 1)
end

return T
