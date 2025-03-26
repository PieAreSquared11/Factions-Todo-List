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

-- Add remove helper function to todo table
function todo.remove(faction, index)
    local list = todo.get(faction)
    if index >= 1 and index <= #list then
        table.remove(list, index)  -- No need for +1 since we're using 1-based indexing
        todo[faction] = list
    end
end

ChatCmdBuilder.new("f_todo", function (cmd)
    cmd:sub("add :item:text", function (name, item)
        local faction = factions.get_player_faction(name)
        if not faction then
            minetest.chat_send_player(name, "You are not a member of any faction")
            return
        end

        -- Check if player is the faction owner for adding items
        if not factions.player_is_owner(name, faction) then
            minetest.chat_send_player(name, "Only the faction owner can add todo items")
            return
        end
        
        todo.add(faction, item)
        todo.save()
        
        local todo_list = todo.get(faction)
        local message = "Todo list for " .. faction .. ":\n"
        for _, task in ipairs(todo_list) do
            message = message .. "- " .. task .. "\n"
        end
        minetest.chat_send_player(name, message)
    end)

    cmd:sub("list", function(name)
        local faction = factions.get_player_faction(name)
        if not faction then
            minetest.chat_send_player(name, "You are not a member of any faction")
            return
        end

        local todo_list = todo.get(faction)
        if #todo_list == 0 then
            minetest.chat_send_player(name, "Todo list for " .. faction .. " is empty")
            return
        end
        
        local message = "Todo list for " .. faction .. ":\n"
        for _, task in ipairs(todo_list) do
            message = message .. "- " .. task .. "\n"
        end
        minetest.chat_send_player(name, message)
    end)

    cmd:sub("clear", function(name)
        local faction = factions.get_player_faction(name)
        if not faction then
            minetest.chat_send_player(name, "You are not a member of any faction")
            return
        end

        -- Check if player is the faction owner for clearing items
        if not factions.player_is_owner(name, faction) then
            minetest.chat_send_player(name, "Only the faction owner can clear todo items")
            return
        end
        
        todo.clear(faction)
        todo.save()
        
        minetest.chat_send_player(name, "Todo list cleared for faction " .. faction)
    end)

    cmd:sub("remove :number:int", function(name, index)
        local faction = factions.get_player_faction(name)
        if not faction then
            minetest.chat_send_player(name, "You are not a member of any faction")
            return
        end

        -- Check if player is the faction owner for removing items
        if not factions.player_is_owner(name, faction) then
            minetest.chat_send_player(name, "Only the faction owner can remove todo items")
            return
        end

        local todo_list = todo.get(faction)
        if index < 1 or index > #todo_list then
            minetest.chat_send_player(name, "Invalid todo item index")
            return
        end
        
        local removed_item = todo_list[index]
        todo.remove(faction, index)
        todo.save()
        
        minetest.chat_send_player(name, "Removed todo item: " .. removed_item)
    end)
end, {
    description = [[Faction Todo List Commands:
/f_todo list - Show your faction's todo list
/f_todo add <item> - Add an item to your faction's todo list (owner only)
/f_todo remove <index> - Remove an item by its number from your faction's todo list (owner only)
/f_todo clear - Clear all items from your faction's todo list (owner only)

Note: Item numbers in the list start from 1]]
})