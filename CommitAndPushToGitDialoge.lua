-- Define height and width variables
local dialogWidth = 500
local dialogHeight = 100

local dlg = Dialog("Git Commit")

local substrDictionary = {
  --["1 file changed, 0 insertions"] = "Succesful commit",      
  ["nothing added to commit"] = "No changes that can be committed"
}

function parseStringWithDictionary(inputString, substrDictionary)
  local result = inputString
  for key, value in pairs(substrDictionary) do
    if string.find(result, key) then
      return value
    end
  end
  return inputString
end

-- Function to execute shell commands
local function executeCommand(cmd)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Function to check if the folder is a Git repository
local function isGitRepo()
  local filePath = app.activeSprite.filename
  local fileDir = filePath:match("(.*[/\\])") or "./"
  local gitCheckCmd = "cd \"" .. fileDir .. "\" && git rev-parse --is-inside-work-tree"
  local result = executeCommand(gitCheckCmd)
  return result:match("true") ~= nil
end

-- Function to handle commit logic
local function commitChanges(commitMessage)
  local filePath = app.activeSprite.filename
  local fileDir = filePath:match("(.*[/\\])") or "./"
  local commitCmd = "cd \"" .. fileDir .. "\" && git add \"" .. filePath .. "\" && git commit -m \"" .. commitMessage .. "\""
  local commitResult = executeCommand(commitCmd)
  return commitResult
end

-- Function to handle push logic
local function pushChanges()
  local sprite = app.activeSprite
  if not sprite then
    return "No active sprite to push."
  end

  local filePath = sprite.filename
  if filePath == "" then
    return "Please save the file before pushing."
  end

  local fileDir = filePath:match("(.*[/\\])") or "./"
  local pushCmd = "cd \"" .. fileDir .. "\" && git push"
  local pushResult = executeCommand(pushCmd)

  return "Result of push unclear. Let's assume it worked."
end

dlg:entry{
  id = "commitMessage",
  label = "Message:",
  text = "",
  onchange = function()
    local data = dlg.data or {}
    dlg:modify{id="commit", enabled=(data.commitMessage ~= "")}
  end
}

dlg:label{
  id = "output",
  text = "",
  label = "Output:"
}

dlg:button{
  id = "commit",
  text = "Commit",
  enabled = false,
  onclick = function()
    local data = dlg.data or {}
    if data.commitMessage == "" then
      dlg:modify{id="output", text="Please enter a commit message."}
      return
    end

    if not isGitRepo() then
      dlg:modify{id="output", text="This folder is not a Git repository."}
      return
    end

    local returnText = commitChanges(data.commitMessage)
    local result = parseStringWithDictionary(returnText, substrDictionary)
    dlg:modify{id="output", text=result}
  end
}

dlg:button{
  id = "push",
  text = "Push",
  enabled = true,
  onclick = function()
    if not isGitRepo() then
      dlg:modify{id="output", text="This folder is not a Git repository."}
      return
    end

    local returnText = pushChanges()
    local result = parseStringWithDictionary(returnText, substrDictionary)
    dlg:modify{id="output", text=result}
  end
}

dlg:button{
  id = "close",
  text = "Close",
  onclick = function()
    dlg:close()
  end,
}

function errorWindow(displayText)
  local dlg = Dialog("Git Commit Error")
  dlg:label{ text=displayText }
  dlg:show()
end

local sprite = app.activeSprite
if not sprite then
  errorWindow "No active sprite to commit."
  return "No active sprite to commit."
end

if sprite.isModified then
  errorWindow "There are unsaved changes. Please save your file before committing."
  return "There are unsaved changes. Please save your file before committing."
end

local filePath = sprite.filename
if filePath == "" then
  errorWindow "Please save the file before committing."
  return "Please save the file before committing."
end

dlg.bounds = Rectangle(100, 100, dialogWidth, dialogHeight)
dlg:show{ wait=false, width=dialogWidth, height=dialogHeight }
