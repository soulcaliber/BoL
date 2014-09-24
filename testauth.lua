function GetUTC()
	return os.time()
end

local clipText = GetClipboardText()
local timestamp = GetUTC()
local username = GetUser()

print("Text: " .. clipText)
print("Timestamp: " .. timestamp)
print("Username: " .. username)