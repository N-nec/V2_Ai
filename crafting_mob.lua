-- Register the AI mob
minetest.register_entity("v2_ai:crafting_ai_mob", {
    initial_properties = {
        hp_max = 10,
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.35, -0.5, -0.35, 0.35, 0.5, 0.35},
        visual = "mesh",
        mesh = "character.b3d",
        textures = {"character.png"},
        makes_footstep_sound = true,
    },
    inventory = {}, -- Mob's simulated inventory
    craft_timer = 0,

    -- Called every game step
    on_step = function(self, dtime)
        self.craft_timer = self.craft_timer + dtime

        -- Try crafting every 5 seconds
        if self.craft_timer >= 5 then
            self.craft_timer = 0
            self:try_crafting()
        end
    end,

    -- Function to add items to the mob's inventory
    add_to_inventory = function(self, item)
        self.inventory[item] = (self.inventory[item] or 0) + 1
    end,

    -- Function to check if the mob has items in its inventory
    has_items = function(self, itemstack)
        local items = itemstack:to_table()
        local name = items.name
        local count = tonumber(items.count)
        return (self.inventory[name] or 0) >= count
    end,

    -- Function to consume items from the inventory
    consume_items = function(self, itemstack)
        local items = itemstack:to_table()
        local name = items.name
        local count = tonumber(items.count)
        if self:has_items(itemstack) then
            self.inventory[name] = self.inventory[name] - count
            if self.inventory[name] <= 0 then
                self.inventory[name] = nil
            end
            return true
        end
        return false
    end,

    -- Function to try crafting an item
    try_crafting = function(self)
        local all_recipes = minetest.get_all_craft_recipes()
        if not all_recipes then return end

        for _, recipe in ipairs(all_recipes) do
            local input = recipe.items or {}
            local output = recipe.output

            -- Check if the mob has all the required items
            local can_craft = true
            for _, item in ipairs(input) do
                local itemstack = ItemStack(item)
                if not self:has_items(itemstack) then
                    can_craft = false
                    break
                end
            end

            if can_craft then
                -- Craft the item
                for _, item in ipairs(input) do
                    self:consume_items(ItemStack(item))
                end
                local output_item = ItemStack(output)
                self:add_to_inventory(output_item:get_name())
                minetest.chat_send_all("The crafting AI mob crafted: " .. output_item:get_name())
                break
            end
        end
    end,

    -- React to punches (optional, for testing)
    on_punch = function(self, hitter)
        local item = hitter:get_wielded_item():get_name()
        if item and item ~= "" then
            self:add_to_inventory(item)
            minetest.chat_send_player(hitter:get_player_name(), "The mob picked up: " .. item)
        end
    end,
})

-- Spawn the mob in the world
minetest.register_chatcommand("spawn_crafting_ai", {
    params = "",
    description = "Spawns a crafting AI mob",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            local pos = player:get_pos()
            pos.y = pos.y + 1
            minetest.add_entity(pos, "mymod:crafting_ai_mob")
            return true, "Crafting AI mob spawned."
        end
        return false, "Failed to spawn the mob."
    end,
})
