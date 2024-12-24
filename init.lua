-- Register a new entity: Dog AI
minetest.register_entity("v2_ai:dog", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.35, 0, -0.35, 0.35, 1, 0.35},
        visual = "mesh",
        mesh = "character.b3d",
        textures = {"character.png"},
    },

    -- Entity state
    hp = 20,
    behaviors = {
        wander = true,
        follow_player = true,
        gather_resources = false,
    },

    -- Initialization
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_armor_groups({fleshy = 100})
        self.state = "wandering" -- Initial behavior
    end,

    -- Behavior: Wandering
    wander = function(self)
        local pos = self.object:get_pos()
        local new_pos = {
            x = pos.x + math.random(-5, 5),
            y = pos.y,
            z = pos.z + math.random(-5, 5),
        }
        self.object:set_velocity({
            x = (new_pos.x - pos.x) * 0.2,
            y = 0,
            z = (new_pos.z - pos.z) * 0.2,
        })
    end,

    -- Behavior: Following Player
    follow_player = function(self, player)
        local pos = self.object:get_pos()
        local player_pos = player:get_pos()
        local distance = vector.distance(pos, player_pos)

        if distance > 2 and distance < 10 then
            local dir = vector.direction(pos, player_pos)
            self.object:set_velocity(vector.multiply(dir, 2))
        else
            self.object:set_velocity({x = 0, y = 0, z = 0})
        end
    end,

    -- Behavior: Gather Resources
    gather_resources = function(self)
        -- Example: Detect nearby nodes and "collect" them
        local pos = self.object:get_pos()
        local radius = 5
        local nearby_nodes = minetest.find_nodes_in_area(
            vector.subtract(pos, radius),
            vector.add(pos, radius),
            {"default:tree"}
        )
        for _, node_pos in ipairs(nearby_nodes) do
            minetest.remove_node(node_pos)
            break
        end
    end,

 -- Self Improvement 
-- Add experience points and levels
v2_ai = {
    experience = 0,
    level = 1,
    behaviors = {}, -- Track learned behaviors
}

-- Function to grant experience
function v2_ai:gain_experience(amount)
    self.experience = self.experience + amount
    if self.experience >= self.level * 10 then
        self:level_up()
    end
end

-- Level up function
function v2_ai:level_up()
    self.level = self.level + 1
    minetest.chat_send_all("v2 AI leveled up! Level: " .. self.level)
    if self.level % 2 == 0 then
        self:learn_new_behavior()
    end
end

-- Learn new behaviors
function v2_ai:learn_new_behavior()
    local new_behavior = {"gather_resources", "attack_mobs"}[math.random(2)]
    table.insert(self.behaviors, new_behavior)
    minetest.chat_send_all("V2 AI learned a new behavior: " .. new_behavior)
end


    -- Step function (runs every server tick)
    on_step = function(self, dtime)
        if self.state == "wandering" then
            self:wander()
        elseif self.state == "following" then
            local player = minetest.get_connected_players()[1]
            if player then
                self:follow_player(player)
            end
        elseif self.state == "gathering" then
            self:gather_resources()
        end
    end,
})

-- Spawning the AI in the world
minetest.register_chatcommand("spawn_v2_ai", {
    description = "Spawn a Dog AI",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            local pos = player:get_pos()
            pos.y = pos.y + 1
            minetest.add_entity(pos, "v2_ai:dog")
            return true, "Dog AI spawned!"
        end
        return false, "Player not found!"
    end,
})