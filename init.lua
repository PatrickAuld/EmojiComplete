local obj = {}
obj.__index = obj

-- Metadata for Spoon
obj.name = "EmojiSearch"
obj.version = "1.9"
obj.author = "Your Name <your.email@example.com>"
obj.license = "MIT"

-- Function to get the directory where init.lua is located
local function getScriptDir()
    local info = debug.getinfo(1, "S")
    local script_path = info.source:match("@(.*)")
    return script_path:match("(.*)/")
end

-- Get the directory of the current script (init.lua)
local scriptDir = getScriptDir()

-- Path to SQLite database and JSON file created by Python script
obj.db_file = hs.configdir .. "/emoji_selection_history.sqlite"
obj.json_file = scriptDir .. "/emoji_data.json"
obj.db = nil

-- Initialize SQLite database connection
function obj:initDB()
    self.db = hs.sqlite3.open(self.db_file)
    if not self.db then
        hs.alert.show("Failed to open SQLite database!")
        return
    end

    -- Create table to store emoji selection history and version
    local res = self.db:exec([[
        CREATE TABLE IF NOT EXISTS emoji_history (
            emoji TEXT PRIMARY KEY,
            name TEXT,
            tags TEXT,
            last_used INTEGER DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS meta (
            key TEXT PRIMARY KEY,
            value TEXT
        );
    ]])

    if res ~= 0 then
        hs.alert.show("Error creating tables: " .. self.db:errmsg())
        return
    end
end

-- Get the current version stored in the database
function obj:getDatabaseVersion()
    local stmt = self.db:prepare("SELECT value FROM meta WHERE key = 'version'")
    local version = nil
    if stmt then
        for row in stmt:nrows() do
            version = row.value
        end
        stmt:finalize()
    else
        hs.alert.show("Error querying version: " .. self.db:errmsg())
    end
    return version
end

-- Set the version in the database
function obj:setDatabaseVersion(version)
    local stmt = self.db:prepare("INSERT OR REPLACE INTO meta (key, value) VALUES ('version', ?)")
    if stmt then
        stmt:bind_values(version)
        stmt:step()
        stmt:finalize()
    else
        hs.alert.show("Error updating version: " .. self.db:errmsg())
    end
end

-- Delete all emoji data in the database
function obj:clearEmojiData()
    local res = self.db:exec("DELETE FROM emoji_history")
    if res ~= 0 then
        hs.alert.show("Error deleting emoji data: " .. self.db:errmsg())
    else
        hs.alert.show("Emoji data cleared from database.")
    end
end

-- Load JSON file and insert emoji data into the database
function obj:loadEmojiDataFromJSON()
    local jsonFile = io.open(self.json_file, "r")
    if not jsonFile then
        hs.alert.show("JSON file not found at " .. self.json_file)
        return
    end

    local jsonData = jsonFile:read("*a")
    jsonFile:close()

    local parsed_data = hs.json.decode(jsonData)
    if not parsed_data or not parsed_data.version or not parsed_data.emoji_data then
        hs.alert.show("Error parsing JSON file!")
        return
    end

    -- Get the current version from the database
    local db_version = self:getDatabaseVersion()

    -- If the version differs, reload all data
    if db_version ~= parsed_data.version then
        hs.alert.show("Version mismatch! Reloading emoji data.")

        -- Clear existing data
        self:clearEmojiData()

        -- Insert emoji data into the SQLite database
        local count = 0
        for _, emoji in ipairs(parsed_data.emoji_data) do
            local stmt = self.db:prepare("INSERT OR IGNORE INTO emoji_history (emoji, name, tags) VALUES (?, ?, ?)")
            if stmt then
                stmt:bind_values(emoji.emoji, emoji.description, table.concat(emoji.tags, ","))
                stmt:step()
                stmt:finalize()
                count = count + 1
            else
                hs.alert.show("Error preparing insert statement: " .. self.db:errmsg())
            end
        end

        -- Update the version in the database
        self:setDatabaseVersion(parsed_data.version)
        hs.alert.show("Inserted " .. count .. " emojis into the database.")
    else
        hs.alert.show("Database version matches. Skipping reload.")
    end
end

-- Update the selection history for an emoji
function obj:updateSelectionHistory(emoji)
    local timestamp = os.time()
    local stmt = self.db:prepare("UPDATE emoji_history SET last_used = ? WHERE emoji = ?")
    if stmt then
        stmt:bind_values(timestamp, emoji)
        stmt:step()
        stmt:finalize()
    else
        hs.alert.show("Error preparing update statement: " .. self.db:errmsg())
    end
end

-- Search emojis for a single term and return results
function obj:searchForTerm(term)
    term = string.lower(term)
    local results = {}

    -- Prepare SQL query for partial matching and ranking by last_used
    local stmt = self.db:prepare([[
        SELECT emoji, name, tags, last_used 
        FROM emoji_history
        WHERE lower(name) LIKE ? OR lower(tags) LIKE ? 
        ORDER BY last_used DESC
    ]])

    if not stmt then
        hs.alert.show("Error preparing search statement: " .. self.db:errmsg())
        return results  -- Return empty table if the statement preparation fails
    end

    stmt:bind_values("%" .. term .. "%", "%" .. term .. "%")

    -- Iterate through the results and insert into the Lua table
    for row in stmt:nrows() do
        table.insert(results, { text = row.emoji .. " " .. row.name, emoji = row.emoji, last_used = row.last_used })
    end

    stmt:finalize()
    return results
end

-- Split search query by whitespace, search for each term, and aggregate results
function obj:searchEmoji(query)
    local results = {}
    local unique_results = {}

    -- Split query into individual terms
    local terms = hs.fnutils.split(query, " ")

    -- Search for each term and aggregate results
    for _, term in ipairs(terms) do
        local term_results = self:searchForTerm(term)
        for _, result in ipairs(term_results) do
            if not unique_results[result.emoji] then
                table.insert(results, result)
                unique_results[result.emoji] = true  -- Track unique results to avoid duplicates
            end
        end
    end

    return results
end

-- Create a chooser UI for live emoji search
function obj:showEmojiChooser()
    self.chooser = hs.chooser.new(function(selection)
        if selection then
            hs.pasteboard.setContents(selection.emoji)
            hs.alert.show("Copied to clipboard: " .. selection.emoji)

            -- Update selection history for the chosen emoji
            self:updateSelectionHistory(selection.emoji)
        end
    end)

    -- Initialize with all emojis as default choices
    local initial_results = self:searchEmoji("")
    self.chooser:choices(initial_results)

    -- Use queryChangedCallback to update search results as the user types
    self.chooser:queryChangedCallback(function(query)
        local matches = self:searchEmoji(query)
        self.chooser:choices(matches)
    end)

    -- Show the chooser
    self.chooser:show()
end

-- Binding function
function obj:bindHotkeys(mapping)
    local def = {
        search = hs.fnutils.partial(self.showEmojiChooser, self)
    }
    hs.spoons.bindHotkeysToSpec(def, mapping)
end

-- Initialize the database at startup and load JSON data if necessary
function obj:init()
    self:initDB()
    self:loadEmojiDataFromJSON()
end

-- Call init to load the database and prepare the history
obj:init()

return obj
