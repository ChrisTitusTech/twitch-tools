obs = obslua

-- Script properties
local text_source_name = ""
local target_scene_name = ""
local countdown_seconds = 300 -- 5 minutes
local remaining_seconds = 0
local timer_active = false
local timer_callback_active = false

-- Description
function script_description()
    return [[
<h2>Countdown Timer with Scene Switch</h2>
<p>Counts down from 5 minutes in a GDI+ Text source and switches to a specified scene when complete.</p>
<ul>
<li>Select your GDI+ Text source</li>
<li>Select the scene to switch to</li>
<li>Click Start to begin countdown</li>
<li>Click Stop to stop/reset</li>
</ul>
    ]]
end

-- Format time as MM:SS
function format_time(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

-- Update the text source with current time
function update_text_display()
    local source = obs.obs_get_source_by_name(text_source_name)
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", format_time(remaining_seconds))
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

-- Switch to target scene
function switch_scene()
    local scenes = obs.obs_frontend_get_scenes()
    if scenes ~= nil then
        for _, scene_source in ipairs(scenes) do
            local name = obs.obs_source_get_name(scene_source)
            if name == target_scene_name then
                obs.obs_frontend_set_current_scene(scene_source)
                break
            end
        end
        obs.source_list_release(scenes)
    end
end

-- Timer callback function
function timer_callback()
    if not timer_active then
        return
    end
    
    remaining_seconds = remaining_seconds - 1
    
    if remaining_seconds < 0 then
        remaining_seconds = 0
        timer_active = false
        update_text_display()
        switch_scene()
        obs.remove_current_callback()
        timer_callback_active = false
        return
    end
    
    update_text_display()
end

-- Start countdown
function start_countdown()
    if text_source_name == "" then
        obs.script_log(obs.LOG_WARNING, "No text source selected")
        return
    end
    
    if target_scene_name == "" then
        obs.script_log(obs.LOG_WARNING, "No target scene selected")
        return
    end
    
    remaining_seconds = countdown_seconds
    timer_active = true
    update_text_display()
    
    if not timer_callback_active then
        obs.timer_add(timer_callback, 1000)
        timer_callback_active = true
    end
end

-- Stop countdown
function stop_countdown()
    timer_active = false
    remaining_seconds = countdown_seconds
    update_text_display()
    
    if timer_callback_active then
        obs.timer_remove(timer_callback)
        timer_callback_active = false
    end
end

-- Start button callback
function start_button_clicked(props, p)
    start_countdown()
    return false
end

-- Stop button callback
function stop_button_clicked(props, p)
    stop_countdown()
    return false
end

-- Script properties
function script_properties()
    local props = obs.obs_properties_create()
    
    -- Text source selection
    local text_list = obs.obs_properties_add_list(props, "text_source", "GDI+ Text Source", 
        obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source in ipairs(sources) do
            local source_id = obs.obs_source_get_id(source)
            if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(text_list, name, name)
            end
        end
        obs.source_list_release(sources)
    end
    
    -- Scene selection
    local scene_list = obs.obs_properties_add_list(props, "target_scene", "Target Scene", 
        obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local scenes = obs.obs_frontend_get_scenes()
    if scenes ~= nil then
        for _, scene in ipairs(scenes) do
            local name = obs.obs_source_get_name(scene)
            obs.obs_property_list_add_string(scene_list, name, name)
        end
        obs.source_list_release(scenes)
    end
    
    -- Countdown duration
    obs.obs_properties_add_int(props, "countdown_minutes", "Countdown Duration (minutes)", 1, 60, 1)
    
    -- Control buttons
    obs.obs_properties_add_button(props, "start_button", "Start Countdown", start_button_clicked)
    obs.obs_properties_add_button(props, "stop_button", "Stop/Reset", stop_button_clicked)
    
    return props
end

-- Update script settings
function script_update(settings)
    text_source_name = obs.obs_data_get_string(settings, "text_source")
    target_scene_name = obs.obs_data_get_string(settings, "target_scene")
    local minutes = obs.obs_data_get_int(settings, "countdown_minutes")
    
    if minutes > 0 then
        countdown_seconds = minutes * 60
        if not timer_active then
            remaining_seconds = countdown_seconds
            update_text_display()
        end
    end
end

-- Set default values
function script_defaults(settings)
    obs.obs_data_set_int(settings, "countdown_minutes", 5)
end

-- Hotkey callbacks
function start_hotkey(pressed)
    if pressed then
        start_countdown()
    end
end

function stop_hotkey(pressed)
    if pressed then
        stop_countdown()
    end
end

-- Register hotkeys
function script_load(settings)
    local start_hotkey_id = obs.obs_hotkey_register_frontend("countdown_start", "Start Countdown Timer", start_hotkey)
    local stop_hotkey_id = obs.obs_hotkey_register_frontend("countdown_stop", "Stop/Reset Countdown Timer", stop_hotkey)
    
    local hotkey_save_array_start = obs.obs_data_get_array(settings, "start_hotkey")
    local hotkey_save_array_stop = obs.obs_data_get_array(settings, "stop_hotkey")
    obs.obs_hotkey_load(start_hotkey_id, hotkey_save_array_start)
    obs.obs_hotkey_load(stop_hotkey_id, hotkey_save_array_stop)
    obs.obs_data_array_release(hotkey_save_array_start)
    obs.obs_data_array_release(hotkey_save_array_stop)
end

-- Save hotkeys
function script_save(settings)
    local start_hotkey_id = obs.obs_hotkey_register_frontend("countdown_start", "Start Countdown Timer", start_hotkey)
    local stop_hotkey_id = obs.obs_hotkey_register_frontend("countdown_stop", "Stop/Reset Countdown Timer", stop_hotkey)
    
    local hotkey_save_array_start = obs.obs_hotkey_save(start_hotkey_id)
    local hotkey_save_array_stop = obs.obs_hotkey_save(stop_hotkey_id)
    obs.obs_data_set_array(settings, "start_hotkey", hotkey_save_array_start)
    obs.obs_data_set_array(settings, "stop_hotkey", hotkey_save_array_stop)
    obs.obs_data_array_release(hotkey_save_array_start)
    obs.obs_data_array_release(hotkey_save_array_stop)
end

-- Cleanup on script unload
function script_unload()
    if timer_callback_active then
        obs.timer_remove(timer_callback)
    end
end