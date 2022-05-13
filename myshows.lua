-- This mpv user script will mark currently watched episode on MyShows.me
-- You can mark it manually too by pressing 'myshows_mark' (default: W) hotkey.
--
-- Copyright (c) 2016 Andrejs Mivreņiks
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require 'mp.options'
local http = require 'socket.http'

-- Auth data for MyShows.
-- You have to specify it in the ~/.config/mpv/lua-settings/myshows.conf file
-- Or you can just put it in this Lua table as default values.
local config_options = {
    username = "",      -- Your MyShows username
    password_md5 = "",  -- Your MyShows password MD5 hash
}
options.read_options(config_options, "myshows")

local base_url = 'https://api.myshows.me' -- MyShows API base URL
local session_id = nil  -- PHP session id
local timer_obj = nil   -- Main timer object
local marked = false

-------------------------------------
-- On file loaded callback
-- @param event Event data table
-------------------------------------
function on_file_loaded(event)
    mp.observe_property("pause", "bool", on_pause_change)
    marked = false
end

-------------------------------------
-- On file unloaded callback
-- @param event Event data table
-------------------------------------
function on_file_unloaded(event)
    destroy_timer()
    mp.unobserve_property(on_pause_change)
end

-------------------------------------
-- On playback paused/resumed callback
-- @param property_name Property name (should be always 'pause')
-- @param value New property value (true/false)
-------------------------------------
function on_pause_change(property_name, value)
    if property_name ~= 'pause' or marked then return end
    if value then
        destroy_timer()
    else
        setup_timer()
    end
end

-------------------------------------
-- Set up a timer which marks episode as watched in 3/4 of episode duration
-------------------------------------
function setup_timer()
    destroy_timer()
    local time_pos = mp.get_property('time-pos')
    -- mpv returns nil when playback position is at very start
    if time_pos == nil then time_pos = 0 end
    local seconds = mp.get_property('duration')*0.75 - time_pos
    if seconds >= 0 then
        timer_obj = mp.add_timeout(seconds, mark_as_watched)
        msg.debug('Episode will be marked as watched in', seconds, 'seconds')
    end
end

-------------------------------------
-- Stop and destroy currently running timer if exists
-------------------------------------
function destroy_timer()
    if timer_obj ~= nil then
      timer_obj:kill()
      timer_obj = nil
      msg.debug('Timer destroyed')
    end
end

-------------------------------------
-- Mark currently whatched episode as watched on MyShows
-------------------------------------
function mark_as_watched()
    marked = true
    destroy_timer()
    if session_id == nil then
        session_id = myshows_auth(config_options.username, config_options.password_md5)
    end
    local filename = mp.get_property('filename')
    local ep_info, err = myshows_find_episode_info(filename)
    if ep_info == nil then
        msg.error('JSON parse error:', err)
        return
    end
    -- Send API request to mark as watched
    local show_id = ep_info['show']['id']
    local episodes = ep_info['show']['episodes']
    for eid in pairs(episodes) do
        local request = base_url..'/profile/episodes/check/'..eid
        r, c, h, s, resp = http_request(request, session_id)
        if c == 200 then
            msg.info('Episode id', eid, 'has been marked as watched')
            mp.osd_message("Episode has been marked as watched on MyShows", 1)
        else
            msg.error('Failed to mark episode. Status:', s)
            mp.osd_message("Failed to mark episode as watched on MyShows", 1)
        end
    end
end

-------------------------------------
-- Performs MyShows authentication and returns PHP session id
-- @param username Username
-- @param password Password MD5 hash
-------------------------------------
function myshows_auth(username, password)
    if config_options.username == ""
    or config_options.password_md5 == "" then
        msg.warn('MyShows username and password MD5 hash is not specified')
        return nil
    end
    local session_id = nil
    local request = base_url..'/profile/login?login='..username..'&password='..password
    local r, c, h, s, resp = http_request(request, session_id)

    if c == 200 then
        msg.info("Authentication succeeded")
        session_id = string.match(h['set-cookie'], 'PHPSESSID=([^;]*)')
    elseif c == 403 then
        msg.error("Invalid username or password")
    else
        msg.error("Authentication failed")
    end
    return session_id
end

-------------------------------------
-- Returns episode information as Lua table
-- @param filename Full video file name
-------------------------------------
function myshows_find_episode_info(filename)
    local request = base_url..'/shows/search/file/?q='..filename
    r, c, h, s, resp = http_request(request, nil)
    if c ~= 200 then
        return nil, 'Failed to retirieve episode information ('..s..')'
    end
    -- mpv's JSON decoder implementation seems not to like such character
    -- escapes as \/ and UTF-16 \u codes, so we'll have to get rid of those to
    -- avoid issues
    local filter_list = {}
    filter_list['\\/'] = '/'
    filter_list['\\u'] = 'u'
    local json = resp[1]
    for k, v in pairs(filter_list) do
        json = string.gsub(json, k, v)
    end
    return utils.parse_json(json, true)
end

-------------------------------------
-- Sends a HTTP request and returns client, code,
-- headers, status and response data
-- @param url Request URL
-- @param session_id PHP session identification.
-------------------------------------
function http_request(url, session_id)
    local resp = {}
    local cookie = nil
    if session_id ~= nil then
        cookie = 'PHPSESSID='..session_id..';'
    end
    local client, code, headers, status = http.request{
        url=url,
        sink=ltn12.sink.table(resp),
        headers = {
            ['Cookie'] = cookie,
        },
    }
    msg.debug('HTTP request', url, 'status:', status)
    return client, code, headers, status, resp
end

mp.register_event('file-loaded', on_file_loaded)
mp.register_event('end-file', on_file_unloaded)
mp.add_key_binding('W', 'myshows_mark', mark_as_watched)
