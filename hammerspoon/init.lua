local lastMode = nil
local hud = nil
local hideTimer = nil

-- ============================================================
-- Input mode
-- ============================================================

local function currentMode()
	local source = hs.keycodes.currentSourceID()

	if source:find("Japanese") then
		return "ja"
	end

	return "en"
end

-- ============================================================
-- HUD
-- ============================================================

local function showHUD(mode)
	if hud then
		hud:delete()
		hud = nil
	end

	if hideTimer then
		hideTimer:stop()
		hideTimer = nil
	end

	local screen = hs.screen.mainScreen()
	local screenFrame = screen:frame()

	local width = 140
	local height = 140
	local text = mode == "ja" and "あ" or "A"

	hud = hs.canvas.new({
		x = screenFrame.x + (screenFrame.w - width) / 2,
		y = screenFrame.y + (screenFrame.h - height) / 2,
		w = width,
		h = height,
	})

	hud[1] = {
		type = "rectangle",
		action = "fill",
		fillColor = {
			white = 0.08,
			alpha = 0.85,
		},
		roundedRectRadii = {
			xRadius = 24,
			yRadius = 24,
		},
	}

	hud[2] = {
		type = "text",
		text = text,
		textSize = 72,
		textColor = {
			white = 1,
			alpha = 1,
		},
		textAlignment = "center",
	}

	local textSize = hud:minimumTextSize(2, text)

	hud[2].frame = {
		x = (width - textSize.w) / 2,
		y = (height - textSize.h) / 2,
		w = textSize.w,
		h = textSize.h,
	}

	hud:level(hs.canvas.windowLevels.overlay)
	hud:show()

	hideTimer = hs.timer.doAfter(0.5, function()
		if hud then
			hud:delete()
			hud = nil
		end

		hideTimer = nil
	end)
end

-- ============================================================
-- Input source change
-- ============================================================

local function inputSourceChanged()
	local mode = currentMode()

	-- Hammerspoon may fire the callback even when our logical
	-- ja/en mode did not actually change.
	if mode == lastMode then
		return
	end

	lastMode = mode
	showHUD(mode)
end

lastMode = currentMode()

hs.keycodes.inputSourceChanged(inputSourceChanged)

-- ============================================================
-- Text input focus detection
-- ============================================================

local function isTextInput(element)
	if not element then
		return false
	end

	local role = element:role()

	return role == "AXTextField" or role == "AXTextArea" or role == "AXSearchField" or role == "AXComboBox"
end

local function showModeIfTextInput()
	-- Focus may not have moved yet when mouse/key events arrive,
	-- so wait briefly before asking Accessibility for the
	-- currently focused element.
	hs.timer.doAfter(0.05, function()
		local element = hs.uielement.focusedElement()

		if isTextInput(element) then
			showHUD(currentMode())
		end
	end)
end

-- Mouse click -> check whether a text input received focus.
local mouseWatcher = hs.eventtap.new({
	hs.eventtap.event.types.leftMouseUp,
}, function()
	showModeIfTextInput()
	return false
end)

mouseWatcher:start()

-- Tab -> check whether keyboard focus moved into a text input.
local keyboardWatcher = hs.eventtap.new({
	hs.eventtap.event.types.keyUp,
}, function(event)
	local key = hs.keycodes.map[event:getKeyCode()]

	if key == "tab" then
		showModeIfTextInput()
	end

	return false
end)

keyboardWatcher:start()

local imeKeyWatcher = hs.eventtap.new({
	hs.eventtap.event.types.keyUp,
}, function(event)
	local keyCode = event:getKeyCode()

	-- macOS JIS:
	-- Eisu = 102
	-- Kana = 104
	if keyCode == 102 or keyCode == 104 then
		hs.timer.doAfter(0.03, function()
			showHUD(currentMode())
		end)
	end

	return false
end)

imeKeyWatcher:start()
