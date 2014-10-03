local html = require("irc.html")
local default_handler = function(url, s)
	local title = s:match("<[Tt][Ii][Tt][Ll][Ee]>([^<]*)<")
	title = title:gsub("%s", " ")
	return title and "Title: " .. html.unescape(title)
end

local handlers = {
	-- TODO, add more handlers
	--["twitter.com"] = function(url, s)
		--if url:match()
	--end
}

local limited_sink = function(t, max)
	local l = 0
	return function(s)
		l = l + #s
		table.insert(t, s)
		if l >= max then
			error("Max reached")
		end
	end
end

return function(irc)
	irc:add_hook("url_info", "on_non_cmd_privmsg", function(irc, state, channel, msg)
		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"
		local https = require("ssl.https")
		local url = require("socket.url")
		for uri in msg:gmatch("https?://%S+") do
			local parsed = url.parse(uri)
			if parsed and parsed.scheme then -- idk if it can return nil
				local t = {}
				local request = ({http=http, https=https})[parsed.scheme].request
				local success, _, response_code = pcall(request, {
					url = uri,
					sink = limited_sink(t, 1024 * 1024) -- 1MiB should be enough
				})
				local handler = handlers[parsed.host] or default_handler
				local url_info = handler(uri, table.concat(t))
				if url_info then
					irc:privmsg(channel, url_info)
				end
			end
		end
	end)
end
