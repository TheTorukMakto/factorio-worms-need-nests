function validate_global_tables()
    if not global.doomed_worms then global.doomed_worms = {} end
end

script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    local surface = event.entity.surface
    local force = entity.force
    local search_radius = 20

    -- this is probably a biter spawner
    if entity.type == "unit-spawner" and entity.force.name == "enemy" then

        -- find worms around the destroyed biter spawner
        -- we may be marking them to be killed
        local worms = surface.find_entities_filtered{
            position = entity.position,
            radius = search_radius,
            force = force,
            type = "turret",
        }

        -- but we need to find other nests that could
        -- keep the worm alive
        for _, worm in pairs(worms) do
            local other_nests = surface.find_entities_filtered{
                position = worm.position,
                radius = search_radius,
                force = force,
                type = "unit-spawner",
            }

            -- and yes, dead nests will still show up here, we need to trim them
            for k, other_nest in pairs(other_nests) do
                if other_nest.health == 0 then table.remove(other_nests, k) end
            end

            -- and if no other nests are found, mark the worm
            -- for removal
            if #other_nests == 0 then
                validate_global_tables()
                table.insert(global.doomed_worms, worm)
            end
        end
    end
end)


script.on_nth_tick(6, function(event)
    -- no worms, no need to do anything
    validate_global_tables()
    if #global.doomed_worms == 0 then return end

    -- and now we damage worms that have been marked as not having a nearby nest
    for k, worm in pairs(global.doomed_worms) do
        if worm.valid then
            worm.damage(math.random(1,3), worm.force)
        else
            -- clean up the table if the worm doesn't exist
            global.doomed_worms[k] = nil
        end
    end
end)