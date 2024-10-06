local monkeypatch = require("sticky-quickfix.monkeypatch")

return {
	setup = function()
		monkeypatch.start()
	end,
	start = function()
		monkeypatch.start()
	end,
	stop = function()
		monkeypatch.stop()
	end,
}
