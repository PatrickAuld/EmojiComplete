local mod = {}
log = hs.logger.new('emojicomplete', 'info')

-- Emojicomplete
function mod.emojicomplete()
    local EMOJI_ENDPOINT = 'https://emojifinder.com/*/ajax.php?action=search&query=%s'
    local current = hs.application.frontmostApplication()
    local tab = nil
    local copy = nil
    local choices = {}

    local chooser = hs.chooser.new(function(choosen)
        if copy then copy:delete() end
        if tab then tab:delete() end
        current:activate()
        hs.eventtap.keyStrokes(choosen.text)
    end)

    -- Removes all items in list
    function reset()
        chooser:choices({})
    end

    tab = hs.hotkey.bind('', 'tab', function()
        local id = chooser:selectedRow()
        local item = choices[id]
        -- If no row is selected, but tab was pressed
        if not item then return end
        chooser:query(item.text)
        reset()
        updateChooser()
    end)

    copy = hs.hotkey.bind('cmd', 'c', function()
        local id = chooser:selectedRow()
        local item = choices[id]
        if item then
            chooser:hide()
            hs.pasteboard.setContents(item.text)
            hs.alert.show("Copied to clipboard", 1)
        else
            hs.alert.show("No search result to copy", 1)
        end
    end)

    function updateChooser()
        local string = chooser:query()
        local query = hs.http.encodeForQuery(string)
        -- Reset list when no query is given
        if string:len() == 0 then return reset() end

        hs.http.asyncGet(string.format(EMOJI_ENDPOINT, query), nil, function(status, data)
            if not data then return end

            local ok, results = pcall(function() return hs.json.decode(data) end)
            if not ok then return end
            choices = hs.fnutils.imap(results["results"], function(result)
                local hex = tonumber(result.Code, 16)
                local name = string.lower(result.Name):gsub("^%l", string.upper)
                return {
                    ["text"] = utf8.char(hex),
                    ["subText"] = name,
                }
            end)

            chooser:choices(choices)
        end)
    end

    chooser:queryChangedCallback(updateChooser)

    chooser:searchSubText(false)

    chooser:show()
end

function mod.registerDefaultBindings(mods, key)
    mods = mods or {"cmd", "alt", "ctrl"}
    key = key or "E"
    hs.hotkey.bind(mods, key, mod.emojicomplete)
end

return mod
