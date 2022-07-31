RegisterNetEvent('sowing:saveCoord')
AddEventHandler('sowing:saveCoord', function(text)

    local file, path

    -- FILENAME
    local filename = ("sowing_coords__%s.txt"):format(os.date("%y_%m_%d"))

    path = filename -- ROOT DIRECTORY
    --path = ("resources/%s/%s"):format(GetCurrentResourceName(), filename) -- SCRIPT DIRECTORY

    -- SEPARATOR
    local separator = ("-- ------------- %s ------------ --\n"):format(os.date("%X"))

    -- WRITE
    file = io.open(path, "a")
    file:write(separator .. text)
    file:close()
end)