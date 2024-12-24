-- Register the AI mob
minetest.register_entity("v2_ai:ai_mob", {
    initial_properties = {
        hp_max = 20,
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.35, -0.5, -0.35, 0.35, 0.5, 0.35},
        visual = "mesh",
        mesh = "character.b3d",
        textures = {"character.png"},
        makes_footstep_sound = true,
    },
    inventory = {}, -- Mob's simulated inventory
    timer = 0,
    target = nil,

    -- Called when the mob is activated
    on_activate = function(self, staticdata, dtime_s)
        self.inventory = {}
    end,

    -- Add items to inventory
    add_to_inventory = function(self, item)
        self.inventory[item] = (self.inventory[item] or 0) + 1
    end,

    -- Check if the mob has an item
    has_items = function(self, itemstack)
        local items = itemstack:to_table()
        local name = items.name
        local count = tonumber(items.count)
        return (self.inventory[name] or 0) >= count
    end,

    -- Consume items from inventory
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

    -- Building logic
    build_structure = function(self, pos)
        -- Example: Build a 3x3 wall
        for x = -1, 1 do
            for y = 0, 2 do
                local block_pos = vector.add(pos, {x = x, y = y, z = 0})
                if minetest.get_node(block_pos).name == "air" then
                    minetest.set_node(block_pos, {name = "default:wood"})
                end
            end
        end
    end,

    -- Crafting logic
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
                minetest.chat_send_all("The AI mob crafted: " .. output_item:get_name())
                break
            end
        end
    end,

    -- Attack logic
    attack_target = function(self, target)
        if not target or not target:get_pos() then return end

        local pos = self.object:get_pos()
        local target_pos = target:get_pos()
        local direction = vector.subtract(target_pos, pos)
        local dist = vector.length(direction)

        if dist <= 1.5 then
            -- Attack target if in range
            target:punch(self.object, 1.0, {
                full_punch_interval = 1.0,
                damage_groups = {fleshy = 5},
            })
            minetest.chat_send_all("The AI mob attacked " .. target:get_player_name())
        else
            -- Move towards the target
            self.object:set_velocity(vector.multiply(vector.normalize(direction), 2))
        end
    end,

    -- Main behavior
    on_step = function(self, dtime)
        self.timer = self.timer + dtime

        if self.timer >= 5 then
            self.timer = 0
            local pos = self.object:get_pos()

            -- Look for players or mobs nearby
            local objects = minetest.get_objects_inside_radius(pos, 10)
            for _, obj in ipairs(objects) do
                if obj:is_player() or obj:get_luaentity() then
                    self.target = obj
                    break
                end
            end

            -- Attack logic
            if self.target then
                self:attack_target(self.target)
            else
                -- Build or craft if no target
                self:build_structure(vector.add(pos, {x = 0, y = 1, z = 0}))
                self:try_crafting()
            end
        end
    end,

    -- React to punches
    on_punch = function(self, hitter)
        local item = hitter:get_wielded_item():get_name()
        if item and item ~= "" then
            self:add_to_inventory(item)
            minetest.chat_send_player(hitter:get_player_name(), "The mob picked up: " .. item)
        end
    end,
})

-- Spawn the mob in the world
minetest.register_chatcommand("spawn_ai_mob", {
    params = "",
    description = "Spawns a building, crafting, and attacking AI mob",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            local pos = player:get_pos()
            pos.y = pos.y + 1
            minetest.add_entity(pos, "v2_ai:ai_mob")
            return true, "AI mob spawned."
        end
        return false, "Failed to spawn the mob."
    end,
})
