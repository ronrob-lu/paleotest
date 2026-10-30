paleotest = {}

-- Provide fallback stubs if mobkit or mob_core are missing
-- Overwrite mobkit.get_stand_pos immediately if mobkit exists to fix the nil index crash
if mobkit and mobkit.get_stand_pos then
    local old_get_stand_pos = mobkit.get_stand_pos
    mobkit.get_stand_pos = function(thing)
        local pos
        local colbox
        if type(thing) == "table" then
            if thing.object and thing.object.get_pos and thing.object.get_properties then
                pos = thing.object:get_pos()
                local props = thing.object:get_properties()
                if props then
                    colbox = props.collisionbox
                end
            end
        elseif type(thing) == "userdata" then
            if thing.get_pos and thing.get_properties then
                pos = thing:get_pos()
                local props = thing:get_properties()
                if props then
                    colbox = props.collisionbox
                end
            end
        else
            return false
        end
        if pos and colbox then
            return mobkit.pos_shift(pos, { y = colbox[2] + 0.01 }), pos
        elseif pos then
            return pos, pos
        end
        return nil
    end
end

if not mobkit then
    mobkit = {
        statfunc = function(self)
            return minetest.serialize(self.memory or {})
        end,
        actfunc = function(self, staticdata, dtime_s)
            if not self then return end
            self.memory = (staticdata and staticdata ~= "" and minetest.deserialize(staticdata)) or self.memory or {}
            self.hq_queue = self.hq_queue or {}
            self.lq_queue = self.lq_queue or {}
            self.punch_timer = self.punch_timer or 0
            self.dtime = dtime_s or 0
        end,
        stepfunc = function(self, dtime, moveresult)
            if not self then return end
            self.dtime = dtime or 0.1
            if self.punch_timer and self.punch_timer > 0 then
                self.punch_timer = self.punch_timer - dtime
            end

            mob_core.collision_detection(self)

            if self.logic then
                self:logic()
            elseif self.brainfunc then
                self:brainfunc()
            end

            if self.hq_queue and #self.hq_queue > 0 then
                local top_hq = self.hq_queue[#self.hq_queue]
                if top_hq and top_hq.func then
                    local done = top_hq.func(self)
                    if done then
                        table.remove(self.hq_queue, #self.hq_queue)
                    end
                end
            end

            if self.lq_queue and #self.lq_queue > 0 then
                local top_lq = self.lq_queue[1]
                if top_lq then
                    local done = top_lq(self)
                    if done then
                        table.remove(self.lq_queue, 1)
                    end
                end
            end
        end,
        recall = function(self, key)
            if not self then return nil end
            if self.memory and self.memory[key] ~= nil then return self.memory[key] end
            return self[key]
        end,
        remember = function(self, key, val)
            if self then
                self.memory = self.memory or {}
                self.memory[key] = val
                self[key] = val
            end
            return val
        end,
        is_alive = function(self)
            return self and self.object and self.object:get_hp() and self.object:get_hp() > 0
        end,
        timer = function(self, s)
            if not self then return false end
            self._timers = self._timers or {}
            self._timers[s] = (self._timers[s] or 0) + (self.dtime or 0.1)
            if self._timers[s] >= s then
                self._timers[s] = 0
                return true
            end
            return false
        end,
        get_stand_pos = function(thing)
            if not thing then return {x=0, y=0, z=0} end
            if type(thing) == "table" and thing.object then
                return thing.object:get_pos() or {x=0, y=0, z=0}
            end
            if thing.get_pos then
                return thing:get_pos() or {x=0, y=0, z=0}
            end
            return {x=0, y=0, z=0}
        end,
        get_queue_priority = function(self)
            if self and self.hq_queue and #self.hq_queue > 0 then
                return self.hq_queue[#self.hq_queue].prty or 0
            end
            return 0
        end,
        is_queue_empty_high = function(self)
            return not self or not self.hq_queue or #self.hq_queue == 0
        end,
        is_queue_empty_low = function(self)
            return not self or not self.lq_queue or #self.lq_queue == 0
        end,
        clear_queue_high = function(self)
            if self then self.hq_queue = {} end
        end,
        clear_queue_low = function(self)
            if self then self.lq_queue = {} end
        end,
        queue_high = function(self, func, prty)
            if not self then return end
            self.hq_queue = self.hq_queue or {}
            prty = prty or 0
            local cur_prty = mobkit.get_queue_priority(self)
            if prty > cur_prty then
                self.hq_queue = {}
                table.insert(self.hq_queue, {func = func, prty = prty})
            elseif prty == cur_prty then
                if #self.hq_queue > 0 then
                    self.hq_queue[#self.hq_queue] = {func = func, prty = prty}
                else
                    table.insert(self.hq_queue, {func = func, prty = prty})
                end
            end
        end,
        queue_low = function(self, func)
            if not self then return end
            self.lq_queue = self.lq_queue or {}
            table.insert(self.lq_queue, func)
        end,
        animate = function(self, anim)
            if not self or not self.object or not self.animation or not self.animation[anim] then return end
            if self.current_anim == anim then return end
            local a = self.animation[anim]
            local speed = a.speed or 15
            local loop = a.loop
            if loop == nil then loop = true end
            self.object:set_animation(a.range, speed, 0, loop)
            self.current_anim = anim
        end,
        make_sound = function(self, sound_name)
            if not self or not self.sounds or not self.sounds[sound_name] then return end
            local spec = self.sounds[sound_name]
            if type(spec) == "table" and spec.name then
                local pitch = 1.0
                if self.child and self.sounds.alter_child_pitch then pitch = 1.5 end
                minetest.sound_play(spec.name, {
                    object = self.object,
                    gain = spec.gain or 1.0,
                    max_hear_distance = spec.distance or 16,
                    pitch = pitch,
                })
            end
        end,
        turn2yaw = function(self, tyaw, rate)
            if not self or not self.object or not tyaw then return end
            rate = rate or 4
            local yaw = self.object:get_yaw() or 0
            local diff = tyaw - yaw
            while diff < -math.pi do diff = diff + 2 * math.pi end
            while diff > math.pi do diff = diff - 2 * math.pi end
            local step = rate * (self.dtime or 0.1)
            if math.abs(diff) <= step then
                self.object:set_yaw(tyaw)
            else
                self.object:set_yaw(yaw + (diff > 0 and step or -step))
            end
        end,
        lq_turn2pos = function(self, target_pos)
            local func = function(self)
                local pos = self.object:get_pos()
                if not pos or not target_pos then return true end
                local dir = vector.direction(pos, target_pos)
                local tyaw = minetest.dir_to_yaw(dir)
                mobkit.turn2yaw(self, tyaw, 6)
                local yaw = self.object:get_yaw() or 0
                if math.abs(tyaw - yaw) < 0.1 then return true end
            end
            mobkit.queue_low(self, func)
        end,
        lq_idle = function(self, duration, anim)
            duration = duration or 1
            anim = anim or "stand"
            local timer = duration
            local func = function(self)
                mobkit.animate(self, anim)
                local vel = self.object:get_velocity()
                if vel then self.object:set_velocity({x = 0, y = vel.y, z = 0}) end
                timer = timer - (self.dtime or 0.1)
                if timer <= 0 then return true end
            end
            mobkit.queue_low(self, func)
        end,
        lq_fallover = function(self)
            local func = function(self)
                mobkit.animate(self, "sleep")
                return true
            end
            mobkit.queue_low(self, func)
        end,
        hq_follow = function(self, prty, target)
            local func = function(self)
                if not target or not target:get_pos() then return true end
                local pos = mobkit.get_stand_pos(self.object)
                if not pos then return true end
                local tpos = target:get_pos()
                local dist = vector.distance(pos, tpos)
                if dist > 3 then
                    mob_core.goto_next_waypoint(self, tpos)
                else
                    mobkit.lq_idle(self, 1, "stand")
                end
            end
            mobkit.queue_high(self, func, prty)
        end,
        get_nearby_player = function(self)
            if not self or not self.object then return nil end
            local pos = self.object:get_pos()
            if not pos then return nil end
            local range = self.view_range or 16
            local closest, min_d = nil, range + 1
            for _, player in ipairs(minetest.get_connected_players()) do
                local ppos = player:get_pos()
                if ppos then
                    local d = vector.distance(pos, ppos)
                    if d < min_d then
                        min_d = d
                        closest = player
                    end
                end
            end
            return closest
        end,
        get_closest_entity = function(self, name_or_tbl)
            if not self or not self.object then return nil end
            local pos = self.object:get_pos()
            if not pos then return nil end
            local range = self.view_range or 16
            local objs = minetest.get_objects_inside_radius(pos, range)
            local closest, min_d = nil, range + 1
            for _, obj in ipairs(objs) do
                if obj ~= self.object then
                    local luaent = obj:get_luaentity()
                    if luaent then
                        local match = false
                        if type(name_or_tbl) == "string" and luaent.name == name_or_tbl then
                            match = true
                        elseif type(name_or_tbl) == "table" then
                            for _, n in ipairs(name_or_tbl) do
                                if luaent.name == n then match = true break end
                            end
                        end
                        if match then
                            local d = vector.distance(pos, obj:get_pos())
                            if d < min_d then
                                min_d = d
                                closest = obj
                            end
                        end
                    end
                end
            end
            return closest
        end,
        heal = function(self, amount)
            if not mobkit.is_alive(self) then return end
            local hp = self.object:get_hp() + (amount or 1)
            if self.max_hp and hp > self.max_hp then hp = self.max_hp end
            self.object:set_hp(hp)
        end,
        hurt = function(self, amount)
            if not mobkit.is_alive(self) then return end
            local hp = self.object:get_hp() - (amount or 1)
            if hp <= 0 then
                self.object:set_hp(0)
                mob_core.on_die(self)
            else
                self.object:set_hp(hp)
                mobkit.make_sound(self, "hurt")
            end
        end,
    }
end

if not mob_core then
    mob_core = {
        get_name_proper = function(name)
            if not name then return "" end
            local parts = name:split(":")
            local mob_name = parts[2] or parts[1]
            return (mob_name:gsub("_", " "):gsub("^%l", string.upper))
        end,
        on_activate = function(self, staticdata, dtime_s)
            if not self then return end
            self.gender = mobkit.recall(self, "gender") or (math.random(1, 2) == 1 and "male" or "female")
            mobkit.remember(self, "gender", self.gender)
            self.growth_stage = mobkit.recall(self, "growth_stage") or 4
            mobkit.remember(self, "growth_stage", self.growth_stage)
            mob_core.set_textures(self)
            local scale = self.scale_stage4 or 1
            if self.growth_stage == 1 then scale = self.scale_stage1 or 0.25
            elseif self.growth_stage == 2 then scale = self.scale_stage2 or 0.5
            elseif self.growth_stage == 3 then scale = self.scale_stage3 or 0.75 end
            mob_core.set_scale(self, scale)
        end,
        collision_detection = function(self)
            if not self or not self.object then return end
            local pos = self.object:get_pos()
            if not pos then return end
            local node_at = minetest.get_node(pos)
            local node_below = minetest.get_node({x = pos.x, y = pos.y - 0.5, z = pos.z})
            local drawtype = minetest.registered_nodes[node_at.name] and minetest.registered_nodes[node_at.name].drawtype
            self.isinliquid = (drawtype == "liquid" or drawtype == "flowingliquid") and node_at.name or false
            self.isonground = not self.isinliquid and (node_below.name ~= "air")
        end,
        vitals = function(self) end,
        random_sound = function(self)
            if math.random(1, 10) == 1 then
                mobkit.make_sound(self, "random")
            end
        end,
        growth = function(self)
            if not self then return end
            if self.child and self.growth_stage and self.growth_stage < 4 then
                self.growth_timer = (self.growth_timer or 0) + 1
                if self.growth_timer >= 600 then
                    self.growth_timer = 0
                    self.growth_stage = self.growth_stage + 1
                    mobkit.remember(self, "growth_stage", self.growth_stage)
                    if self.growth_stage == 4 then
                        self.child = mobkit.remember(self, "child", false)
                    end
                    mob_core.set_textures(self)
                    local scale = self.scale_stage4 or 1
                    if self.growth_stage == 1 then scale = self.scale_stage1 or 0.25
                    elseif self.growth_stage == 2 then scale = self.scale_stage2 or 0.5
                    elseif self.growth_stage == 3 then scale = self.scale_stage3 or 0.75 end
                    mob_core.set_scale(self, scale)
                end
            end
        end,
        protect = function(self, clicker, toggle) end,
        nametag = function(self, clicker) end,
        on_punch_basic = function(self, puncher, tool_capabilities, dir)
            if not mobkit.is_alive(self) then return end
            local damage = (tool_capabilities and tool_capabilities.damage_groups and tool_capabilities.damage_groups.fleshy) or 1
            mobkit.hurt(self, damage)
            if dir and self.object then
                self.object:add_velocity({x = dir.x * 3, y = 2, z = dir.z * 3})
            end
        end,
        on_punch_retaliate = function(self, puncher, aqua, runaway)
            if puncher and mobkit.is_alive(self) then
                mob_core.logic_attack_player(self, 20, puncher)
            end
        end,
        on_punch_runaway = function(self, puncher, aqua, runaway)
            if puncher and mobkit.is_alive(self) then
                mob_core.logic_runaway_mob(self, 20, {puncher:get_player_name()})
            end
        end,
        on_die = function(self)
            if not self or not self.object then return end
            mobkit.make_sound(self, "death")
            local pos = self.object:get_pos()
            if pos and self.drops then
                for _, drop in ipairs(self.drops) do
                    if math.random(1, drop.chance or 1) == 1 then
                        local count = math.random(drop.min or 1, drop.max or 1)
                        minetest.add_item(pos, drop.name .. " " .. count)
                    end
                end
            end
            self.object:remove()
        end,
        register_spawn_egg = function(mob_name, color1, color2)
            local desc = mob_core.get_name_proper(mob_name)
            local raw_name = mob_name:split(":")[2] or mob_name
            local color1_hex = color1 or "ffffff"
            local color2_hex = color2 or "ffffff"
            minetest.register_craftitem("paleotest:egg_spawn_" .. raw_name, {
                description = desc .. " Spawn Egg",
                inventory_image = "paleotest_spawn_egg_base.png^[multiply:#" .. color1_hex ..
                                  "^paleotest_spawn_egg_overlay.png^[multiply:#" .. color2_hex,
                on_place = function(itemstack, placer, pointed_thing)
                    local pos = minetest.get_pointed_thing_position(pointed_thing, true)
                    if pos then
                        local ent = minetest.registered_entities[mob_name]
                        if ent and ent.collisionbox then
                            pos.y = pos.y - ent.collisionbox[2]
                        else
                            pos.y = pos.y + 0.5
                        end
                        minetest.add_entity(pos, mob_name)
                        if not minetest.settings:get_bool("creative_mode") then
                            itemstack:take_item()
                            return itemstack
                        end
                    end
                end,
            })
        end,
        set_scale = function(self, scale)
            if not self or not self.object then return end
            scale = scale or 1
            local base_vis = self.visual_size or {x = 1, y = 1}
            local base_col = self.collisionbox or {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
            self.object:set_properties({
                visual_size = {x = base_vis.x * scale, y = base_vis.y * scale},
                collisionbox = {
                    base_col[1] * scale,
                    base_col[2] * scale,
                    base_col[3] * scale,
                    base_col[4] * scale,
                    base_col[5] * scale,
                    base_col[6] * scale
                }
            })
        end,
        set_textures = function(self)
            if not self or not self.object then return end
            local tex
            if self.child and self.child_textures then
                tex = self.child_textures
            elseif self.gender == "female" and self.female_textures then
                tex = self.female_textures
            elseif self.male_textures then
                tex = self.male_textures
            elseif self.textures then
                tex = self.textures
            end
            if tex then
                self.texture_no = self.texture_no or math.random(1, #tex)
                local chosen = tex[self.texture_no] or tex[1]
                self.object:set_properties({textures = {chosen}})
            end
        end,
        spawn_child = function(pos, mob)
            local child = minetest.add_entity(pos, mob)
            if child then
                local luaent = child:get_luaentity()
                if luaent then
                    luaent.child = mobkit.remember(luaent, "child", true)
                    luaent.growth_stage = mobkit.remember(luaent, "growth_stage", 1)
                    luaent.growth_timer = mobkit.remember(luaent, "growth_timer", 0)
                    mob_core.set_scale(luaent, luaent.scale_stage1 or 0.25)
                    mob_core.set_textures(luaent)
                end
            end
            return child
        end,
        goto_next_waypoint = function(self, target_pos)
            if not self or not self.object or not target_pos then return end
            local pos = mobkit.get_stand_pos(self.object)
            if not pos then return end
            local dir = vector.direction(pos, target_pos)
            local tyaw = minetest.dir_to_yaw(dir)
            mobkit.turn2yaw(self, tyaw, 6)
            local speed = self.max_speed or 3
            local vel = self.object:get_velocity() or {x = 0, y = 0, z = 0}
            local move_dir = minetest.yaw_to_dir(self.object:get_yaw() or tyaw)
            self.object:set_velocity({
                x = move_dir.x * speed,
                y = vel.y,
                z = move_dir.z * speed
            })
            mobkit.animate(self, "walk")
        end,
        swim_to_next_waypoint = function(self, target_pos)
            if not self or not self.object or not target_pos then return end
            local pos = self.object:get_pos()
            local dir = vector.direction(pos, target_pos)
            local tyaw = minetest.dir_to_yaw(dir)
            mobkit.turn2yaw(self, tyaw, 4)
            local speed = (self.max_speed or 3) * 0.8
            self.object:set_velocity({
                x = dir.x * speed,
                y = dir.y * speed,
                z = dir.z * speed
            })
            mobkit.animate(self, self.animation and self.animation.swim and "swim" or "walk")
        end,
        fly_to_next_waypoint = function(self, target_pos)
            if not self or not self.object or not target_pos then return end
            local pos = self.object:get_pos()
            local dir = vector.direction(pos, target_pos)
            local tyaw = minetest.dir_to_yaw(dir)
            mobkit.turn2yaw(self, tyaw, 5)
            local speed = self.max_speed or 5
            self.object:set_velocity({
                x = dir.x * speed,
                y = dir.y * speed,
                z = dir.z * speed
            })
            mobkit.animate(self, self.animation and self.animation.fly and "fly" or "walk")
        end,
        hq_roam = function(self, prty, slow)
            local func = function(self)
                local stand_pos = mobkit.get_stand_pos(self.object)
                if not stand_pos then return true end
                if not self.roam_target or vector.distance(stand_pos, self.roam_target) < 2 or math.random(1, 100) == 1 then
                    local pos = mobkit.get_stand_pos(self.object)
                    if not pos then return true end
                    local rx = math.random(-12, 12)
                    local rz = math.random(-12, 12)
                    self.roam_target = {x = pos.x + rx, y = pos.y, z = pos.z + rz}
                end
                mob_core.goto_next_waypoint(self, self.roam_target)
            end
            mobkit.queue_high(self, func, prty)
        end,
        hq_aqua_roam = function(self, prty, speed, min_d, max_d)
            local func = function(self)
                if not self.roam_target or vector.distance(self.object:get_pos(), self.roam_target) < 3 or math.random(1, 80) == 1 then
                    local pos = self.object:get_pos()
                    local rx = math.random(-12, 12)
                    local ry = math.random(-4, 4)
                    local rz = math.random(-12, 12)
                    self.roam_target = {x = pos.x + rx, y = pos.y + ry, z = pos.z + rz}
                end
                mob_core.swim_to_next_waypoint(self, self.roam_target)
            end
            mobkit.queue_high(self, func, prty)
        end,
        hq_aerial_roam = function(self, prty, speed)
            local func = function(self)
                if not self.roam_target or vector.distance(self.object:get_pos(), self.roam_target) < 4 or math.random(1, 100) == 1 then
                    local pos = self.object:get_pos()
                    local rx = math.random(-20, 20)
                    local ry = math.random(-5, 10)
                    local rz = math.random(-20, 20)
                    self.roam_target = {x = pos.x + rx, y = pos.y + ry, z = pos.z + rz}
                end
                mob_core.fly_to_next_waypoint(self, self.roam_target)
            end
            mobkit.queue_high(self, func, prty)
        end,
        hq_liquid_recovery = function(self, prty, anim)
            local func = function(self)
                if not self.isinliquid then return true end
                local vel = self.object:get_velocity() or {x = 0, y = 0, z = 0}
                self.object:set_velocity({x = vel.x, y = 3, z = vel.z})
                mobkit.animate(self, anim or "walk")
            end
            mobkit.queue_high(self, func, prty)
        end,
        logic_attack_mob = function(self, prty, target)
            if not target or not target:get_pos() then return end
            local func = function(self)
                if not target or not target:get_pos() then return true end
                local pos = mobkit.get_stand_pos(self.object)
                if not pos then return true end
                local tpos = target:get_pos()
                local dist = vector.distance(pos, tpos)
                local reach = self.reach or 3
                if dist > reach then
                    mob_core.goto_next_waypoint(self, tpos)
                else
                    mobkit.lq_turn2pos(self, tpos)
                    mobkit.animate(self, "punch")
                    if (self.punch_timer or 0) <= 0 then
                        target:punch(self.object, 1.0, {
                            full_punch_interval = 0.5,
                            damage_groups = {fleshy = self.damage or 5}
                        }, nil)
                        self.punch_timer = self.punch_cooldown or 1
                    end
                    return true
                end
            end
            mobkit.queue_high(self, func, prty)
        end,
        logic_attack_mobs = function(self, prty, targets)
            local target = mobkit.get_closest_entity(self, targets or self.targets)
            if target then
                mob_core.logic_attack_mob(self, prty, target)
            end
        end,
        logic_attack_player = function(self, prty, player)
            if player then
                mob_core.logic_attack_mob(self, prty, player)
            end
        end,
        logic_runaway_mob = function(self, prty, predators)
            local pred = mobkit.get_closest_entity(self, predators)
            if pred and pred:get_pos() then
                local func = function(self)
                    if not pred or not pred:get_pos() then return true end
                    local pos = mobkit.get_stand_pos(self.object)
                    if not pos then return true end
                    local ppos = pred:get_pos()
                    local runaway_pos = {x = 2 * pos.x - ppos.x, y = pos.y, z = 2 * pos.z - ppos.z}
                    mob_core.goto_next_waypoint(self, runaway_pos)
                    if vector.distance(pos, ppos) > (self.view_range or 16) then
                        return true
                    end
                end
                mobkit.queue_high(self, func, prty)
            end
        end,
        hq_follow_holding = function(self, prty, player)
            if player and mob_core.follow_holding(self, player) then
                mobkit.hq_follow(self, prty, player)
            end
        end,
        follow_holding = function(self, player)
            if not player or not self.follow then return false end
            local item = player:get_wielded_item():get_name()
            if not item or item == "" then return false end
            for _, name in ipairs(self.follow) do
                if item == name or item:match(name) then return true end
            end
            return false
        end,
        set_owner = function(self, name) if self then self.owner = name end end,
        mount = function(self, player)
            if self and player then
                self.driver = player
                player:set_attach(self.object, "", {x=0, y=0, z=0}, {x=0, y=0, z=0})
            end
        end,
        detach = function(player, offset)
            if player then player:set_detach() end
        end,
        is_mobkit_mob = function(ent) return true end,
        logic_aqua_attack_mobs = function(self, prty, targets)
            local target = mobkit.get_closest_entity(self, targets or self.targets)
            if target then
                mob_core.logic_attack_mob(self, prty, target)
            end
        end,
        logic_aqua_attack_player = function(self, prty, player)
            if player then
                mob_core.logic_attack_mob(self, prty, player)
            end
        end,
        logic_aqua_attack_mob = function(self, prty, target)
            if target then
                mob_core.logic_attack_mob(self, prty, target)
            end
        end,
        hq_aqua_follow_holding = function(self, prty, player)
            if player and mob_core.follow_holding(self, player) then
                mobkit.hq_follow(self, prty, player)
            end
        end,
        hq_takeoff = function(self, prty, height)
            height = height or 6
            local stand_pos = mobkit.get_stand_pos(self.object)
            if not stand_pos then return end
            local target_y = stand_pos.y + height
            local func = function(self)
                local pos = self.object:get_pos()
                if pos and pos.y >= target_y then return true end
                local vel = self.object:get_velocity() or {x = 0, y = 0, z = 0}
                self.object:set_velocity({x = vel.x, y = 3, z = vel.z})
                mobkit.animate(self, "fly")
            end
            mobkit.queue_high(self, func, prty)
        end,
        hq_land = function(self, prty, target_pos)
            local func = function(self)
                if self.isonground then return true end
                local pos = self.object:get_pos()
                if not pos then return true end
                local tpos = target_pos or {x = pos.x, y = pos.y - 10, z = pos.z}
                mob_core.fly_to_next_waypoint(self, tpos)
            end
            mobkit.queue_high(self, func, prty)
        end,
        hq_mount_logic = function(self, prty) end,
        punch_timer = function(self, cooldown)
            if cooldown then self.punch_timer = cooldown end
        end,
        logic_aerial_takeoff_flee_player = function(self, prty, height)
            local player = mobkit.get_nearby_player(self)
            if player then
                mob_core.hq_takeoff(self, prty, height)
            end
        end,
    }
end

-- Sound abstraction helpers
function paleotest.node_sound_stone_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_stone_defaults then
		return default.node_sound_stone_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_stone_defaults then
		return mcl_sounds.node_sound_stone_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_dirt_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_dirt_defaults then
		return default.node_sound_dirt_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_dirt_defaults then
		return mcl_sounds.node_sound_dirt_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_sand_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_sand_defaults then
		return default.node_sound_sand_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_sand_defaults then
		return mcl_sounds.node_sound_sand_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_wood_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_wood_defaults then
		return default.node_sound_wood_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_wood_defaults then
		return mcl_sounds.node_sound_wood_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_leaves_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_leaves_defaults then
		return default.node_sound_leaves_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_leaves_defaults then
		return mcl_sounds.node_sound_leaves_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_metal_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_metal_defaults then
		return default.node_sound_metal_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_metal_defaults then
		return mcl_sounds.node_sound_metal_defaults(table)
	end
	return table or {}
end

-- Node & Tree Growth Abstractions
function paleotest.can_grow(pos)
	if minetest.get_modpath("default") and default.can_grow then
		return default.can_grow(pos)
	end
	local node_above = minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
	local light = minetest.get_node_light(pos)
	return (light and light >= 13) and (node_above.name == "air" or minetest.registered_nodes[node_above.name].buildable_to)
end

function paleotest.sapling_on_place(itemstack, placer, pointed_thing, sapling_name, minp, maxp, interval)
	if minetest.get_modpath("default") and default.sapling_on_place then
		return default.sapling_on_place(itemstack, placer, pointed_thing, sapling_name, minp, maxp, interval)
	end
	return minetest.item_place(itemstack, placer, pointed_thing)
end

function paleotest.get_inventory_drops(pos, listname, drops)
	if minetest.get_modpath("default") and default.get_inventory_drops then
		return default.get_inventory_drops(pos, listname, drops)
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if not inv then return end
	for i = 1, inv:get_size(listname) do
		local stack = inv:get_stack(listname, i)
		if not stack:is_empty() then
			table.insert(drops, stack:take_item(stack:get_count()))
		end
	end
end

paleotest.mobkit_mobs = {}
paleotest.global_walkable = {}
paleotest.global_flora = {}
paleotest.global_leaves = {}
paleotest.global_plants = {}
paleotest.global_liquid = {}

minetest.register_on_mods_loaded(function()
	-- Entities
    for name in pairs(minetest.registered_entities) do
        local mob = minetest.registered_entities[name]
        if mob.get_staticdata == mobkit.statfunc
        and (mob.logic or mob.brainfunc) then
            table.insert(paleotest.mobkit_mobs, name)
        end
	end
	-- Nodes
	for name, def in pairs(minetest.registered_nodes) do
		if name ~= "air" and name ~= "ignore" then
			if def.walkable then
				table.insert(paleotest.global_walkable, name)
			end
			if def.groups and (def.groups.flora or def.groups.flower or def.groups.plant) then
				table.insert(paleotest.global_flora, name)
				table.insert(paleotest.global_plants, name)
			end
			if def.groups and (def.groups.leaves or def.groups.leafdecay) then
				table.insert(paleotest.global_leaves, name)
				table.insert(paleotest.global_plants, name)
			end
			if def.drawtype == "liquid" or (def.groups and def.groups.liquid) then
				table.insert(paleotest.global_liquid, name)
			end
		end
	end
end)

paleotest.global_meat = {}

local common_meat_names = {
	"beef",
	"chicken",
	"mutton",
	"porkchop",
	"meat"
}

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_items) do
		local added = false
		if def.groups and (def.groups.food_meat_raw or def.groups.food_meat) then
			table.insert(paleotest.global_meat, name)
			added = true
		else
			for _, i in ipairs(common_meat_names) do
				if (name:match(i) and (name:match("raw") or name:match("uncooked"))) then
					table.insert(paleotest.global_meat, name)
					added = true
					break
				end
			end
		end
	end
end)

paleotest.global_fish = {}

local common_fish_names = {
	"fish",
	"cod",
	"bass",
	"tuna",
	"salmon"
}

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_items) do
		if def.groups and (def.groups.food_fish_raw or def.groups.food_fish) then
			table.insert(paleotest.global_fish, name)
		else
			for _, i in ipairs(common_fish_names) do
				if name:find(i)
				and (name:find("raw")
				or name:find("uncooked")
				or name:find("cooked")) then
					table.insert(paleotest.global_fish, name)
					break
				end
			end
		end
	end
end)

function paleotest.remove_string(tbl, val)
    for i, v in ipairs(tbl) do
		if v == val then
			return table.remove(tbl, i)
        end
    end
end

function paleotest.find_string(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

local path = minetest.get_modpath("paleotest")

-- API
dofile(path.."/api/api.lua")
dofile(path.."/api/hq_lq.lua")
dofile(path.."/api/register.lua")
if minetest.settings:get_bool("legacy_convert") then
	dofile(path.."/legacy_convert.lua")
end

-- Items
dofile(path.."/nodes.lua")
dofile(path.."/craftitems.lua")
dofile(path.."/crafting.lua")
dofile(path.."/ores.lua")
dofile(path.."/fossil_analyzer.lua")
dofile(path.."/dna_cultivator.lua")
dofile(path.."/feeders.lua")


-- Dinosaurs

dofile(path.."/mobs/brachiosaurus.lua")
dofile(path.."/mobs/carnotaurus.lua")
dofile(path.."/mobs/stegosaurus.lua")
dofile(path.."/mobs/spinosaurus.lua")
dofile(path.."/mobs/triceratops.lua")
dofile(path.."/mobs/tyrannosaurus.lua")
dofile(path.."/mobs/velociraptor.lua")

-- Reptiles
dofile(path.."/mobs/pteranodon.lua")
dofile(path.."/mobs/quetzalcoatlus.lua")
dofile(path.."/mobs/sarcosuchus.lua")

-- Aquatic Mobs
dofile(path.."/mobs/dunkleosteus.lua")
dofile(path.."/mobs/mosasaurus.lua")
dofile(path.."/mobs/plesiosaurus.lua")

-- Mammals
dofile(path.."/mobs/dire_wolf.lua")
dofile(path.."/mobs/elasmotherium.lua")
dofile(path.."/mobs/mammoth.lua")
dofile(path.."/mobs/procoptodon.lua")
dofile(path.."/mobs/smilodon.lua")
dofile(path.."/mobs/thylacoleo.lua")

minetest.log("action", "[MOD] PaleoTest v2.0 Dev loaded")
