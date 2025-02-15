local storage = minetest.get_mod_storage()
local items = {}

todo = {}

function todo.add(faction, item)
    items[faction] = items[faction] or {}
    table.insert(items[faction], item)
end

function todo.save() 
    storage:set_string("items", minetest.serialize(items))
end

function todo.get(faction)
    local stored_items = minetest.deserialize(storage:get_string("items")) or {}
    return stored_items[faction] or {}
end

function todo.clear(faction)
    items[faction] = {}
    storage:set_string("items", minetest.serialize(items))
end

ChatCmdBuilder.new("f_todo", function (cmd)
    cmd:sub("add :item", function (name, item)
        local faction = factions.get_player_faction(name)
        if not faction then
            factions.notify_player(name, "You are not a member of any faction")
            return
        end

        -- Check if player is the faction owner for adding items
        if not factions.player_is_owner(name, faction) then
            factions.notify_player(name, "Only the faction owner can add todo items")
            return
        end
        
        todo.add(faction, item)
        todo.save()
        
        local todo_list = todo.get(faction)
        local message = "Todo list for " .. faction .. ":\n"
        for _, task in ipairs(todo_list) do
            message = message .. "- " .. task .. "\n"
        end
        factions.notify_player(name, message)
    end)

    cmd:sub("list", function(name)
        local faction = factions.get_player_faction(name)
        if not faction then
            factions.notify_player(name, "You are not a member of any faction")
            return
        end

        local todo_list = todo.get(faction)
        if #todo_list == 0 then
            factions.notify_player(name, "Todo list for " .. faction .. " is empty")
            return
        end
        
        local message = "Todo list for " .. faction .. ":\n"
        for _, task in ipairs(todo_list) do
            message = message .. "- " .. task .. "\n"
        end
        factions.notify_player(name, message)
    end)

    cmd:sub("clear", function(name)
        local faction = factions.get_player_faction(name)
        if not faction then
            factions.notify_player(name, "You are not a member of any faction")
            return
        end

        -- Check if player is the faction owner for clearing items
        if not factions.player_is_owner(name, faction) then
            factions.notify_player(name, "Only the faction owner can clear todo items")
            return
        end
        
        todo.clear(faction)
        todo.save()
        
        factions.notify_player(name, "Todo list cleared for faction " .. faction)
    end)
end)