local json = require("json")
local utils = require("irc.utils")

return function(irc)
	irc:add_command("misc", "say", function(irc, state, channel, msg)
		return msg
	end, false)
	irc:add_command("misc", "notice", function(irc, state, channel, msg)
		irc:notice(channel, msg)
	end, false)
	irc:add_command("misc", "nick", function(irc, state, channel, msg)
		return state.nick
	end, false)
	irc:add_command("misc", "user", function(irc, state, channel, msg)
		return state.user
	end, false)
	irc:add_command("misc", "host", function(irc, state, channel, msg)
		return state.host
	end, false)
	irc:add_command("misc", "channel", function(irc, state, channel, msg)
		return channel
	end, false)
	irc:add_command("misc", "me", function(irc, state, channel, msg)
		return irc:action(msg)
	end, false)
	irc:add_command("misc", "prefixes", function(irc, state, channel, msg)
		local prefixes = irc:get_config("prefixes", channel)
		return utils.escape_list(prefixes)
	end, false)
	irc:add_command("misc", "topic", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		assert(irc.channels[channel], "Invalid channel")
		return irc.channels[channel].topic
	end, false)
	irc:add_command("misc", "someone", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		assert(irc.channels[channel], "Invalid channel")
		local user = utils.random_choice_dict(irc.channels[channel].users)
		return irc.channels[channel].users[user].nick
	end, false)
	
	irc:add_command("misc", "button", function(irc, state, channel, msg)
		assert(utils.strip(msg) ~= "", "Empty string")
		local color, background, shadow, msg = msg:match("(%d*) ?(%d*) ?(%d*) ?(.+)")

		color      = irc:fix_color(tonumber(color) or 1)
		background = irc:fix_color(tonumber(background) or 15)
		shadow     = irc:fix_color(tonumber(shadow) or 14)
		
		local utf8 = require("utf8")
		local len = utf8.len(irc:strip_style(msg)) + 4
		
		irc:privmsg(channel, ("\003,%i%s"):format(background, (" "):rep(len)))
		irc:privmsg(channel, ("\003%i,%i  %s\003,%i  \003,%i "):format(color, background, msg, background, shadow))
		irc:privmsg(channel, ("\003,%i%s\0030,%i "):format(background, (" "):rep(len), shadow))
		irc:privmsg(channel, (" \003,%s%s"):format(shadow, (" "):rep(len)))
	end, false)

	local function dice(msg)
		local n, sides, modifier = msg:match("(%d+)d(%d+)([+-]?%d*)")
		
		n = assert(tonumber(n), "Invalid number")
		sides = assert(tonumber(sides), "Invalid number")
		modifier = tonumber(modifier) or 0

		assert(n >= 1,  "Moves his hand as he threw a dice")
		assert(n <= 30, "The dices are all over the floor!")
		assert(sides >= 4,   "What kind of dice has less than 4 sides?")
		assert(sides <= 100, "That's practically a sphere")
		assert(modifier >= -10000, "Modifier is too low")
		assert(modifier <=  10000, "Modifier is too big")
		
		local total = 0
		local results = {}
		for i = 1, n do
			local result = math.random(sides) + modifier
			results[i] = result
			total = total + result
		end
		
		local max = n * (sides + modifier)
		
		return {
			total   = total,
			results = results,
			max     = max
		}
	end
	irc:add_command("misc", "dice", function(irc, state, channel, msg)
		return tostring(dice(msg).total)
	end, false)
	irc:add_command("misc", "dice_f", function(irc, state, channel, msg)
		local result = dice(msg)
		
		return ("Total %i / %i [%.2f%%] :: Results [%s]"):format(
			result.total,
			result.max,
			(result.total / result.max) * 100,
			table.concat(result.results, ", ")
		)
	end, false)
	irc:add_command("misc", "dice_l", function(irc, state, channel, msg)
		return utils.escape_list(dice(msg).results)
	end, false)
	local function random_gauss(mu, sigma)
		-- copied from python's random.py
		local x2pi = math.random() * 2 * math.pi
		local g2rad = math.sqrt(-2.0 * math.log(1.0 - math.random()))
		local z = math.cos(x2pi) * g2rad
		return mu + z * sigma
	end
	irc:add_command("misc", "coin", function(irc, state, channel, coins)
		coins = coins or 1
		if coins < 0 then
			return irc:action(("throws %s coin%s to the floor"):format(math.abs(coins), coins == -1 and "" or "s"))
		elseif coins == 0 then
			return irc:action("moves his hands as if he flipped a coin")
		elseif coins == 1 then
			return "Your result is " .. (math.random(2) == 1 and "tails" or "heads")
		else
			local heads = 0
			if coins < 1000 then
				for i = 1, coins do
					heads = heads + (math.random(2) == 1 and 1 or 0)
				end
			else
				heads = math.floor(random_gauss(coins / 2, math.sqrt(.75 * coins)))
			end
			tails = coins - heads
			return irc:action(("flips %s coins and gets %s head%s and %s tail%s."):format(coins, heads, heads == 1 and "" or "s", tails, tails == 1 and "" or "s"))
		end
	end, false, "int...")

	local flip_table = {
		["!"] = "¡", ['"'] = ",,", ["&"] = "⅋", ["'"] = ",", ["("] = ")",
		[")"] = "(", [","] = "'", ["."] = "˙", ["0"] = "0", ["1"] = "Ɩ",
		["2"] = "ᄅ", ["3"] = "Ɛ", ["4"] = "ㄣ", ["5"] = "ϛ", ["6"] = "9",
		["7"] = "ㄥ", ["8"] = "8", ["9"] = "6", ["<"] = ">", [">"] = "<",
		["?"] = "¿", ["A"] = "∀", ["C"] = "Ɔ", ["E"] = "Ǝ", ["F"] = "Ⅎ",
		["G"] = "פ", ["H"] = "H", ["I"] = "I", ["J"] = "ſ", ["L"] = "˥",
		["M"] = "W", ["N"] = "N", ["P"] = "Ԁ", ["T"] = "┴", ["U"] = "∩",
		["V"] = "Λ", ["Y"] = "⅄", ["["] = "]", ["]"] = "[", ["_"] = "‾",
		["`"] = ",", ["a"] = "ɐ", ["b"] = "q", ["c"] = "ɔ", ["d"] = "p",
		["e"] = "ǝ", ["f"] = "ɟ", ["g"] = "ƃ", ["h"] = "ɥ", ["i"] = "ı",
		["j"] = "ɾ", ["k"] = "ʞ", ["m"] = "ɯ", ["n"] = "u", ["r"] = "ɹ",
		["t"] = "ʇ", ["v"] = "ʌ", ["w"] = "ʍ", ["y"] = "ʎ", ["{"] = "}",
		["}"] = "{", ["⁅"] = "⁆", ["∴"] = "∵"
	}
	for k, v in pairs(utils.deepcopy(flip_table)) do
		flip_table[v] = k
	end
	irc:add_command("misc", "flip", function(irc, state, channel, msg)
		local utf8 = require("utf8")
		return utf8.reverse(utf8.gsub(msg, ".", function(c) return flip_table[c] or c end))
	end, false)
	local morse = {
		["!"] = "---.", ['"'] = ".-..-.", ["$"] = "...-..-", ["'"] = ".----.",
		["("] = "-.--.", [")"] = "-.--.-", ["+"] = ".-.-.", [","] = "--..--",
		["-"] = "-....-", ["."] = ".-.-.-", ["/"] = "-..-.", ["0"] = "-----",
		["1"] = ".----", ["2"] = "..---", ["3"] = "...--", ["4"] = "....-",
		["5"] = ".....", ["6"] = "-....", ["7"] = "--...", ["8"] = "---..",
		["9"] = "----.", [":"] = "---...", [";"] = "-.-.-.", ["="] = "-...-",
		["?"] = "..--..", ["@"] = ".--.-.", ["A"] = ".-", ["B"] = "-...",
		["C"] = "-.-.", ["D"] = "-..", ["E"] = ".", ["F"] = "..-.",
		["G"] = "--.", ["H"] = "....", ["I"] = "..", ["J"] = ".---",
		["K"] = "-.-", ["L"] = ".-..", ["M"] = "--", ["N"] = "-.",
		["O"] = "---", ["P"] = ".--.", ["Q"] = "--.-", ["R"] = ".-.",
		["S"] = "...", ["T"] = "-", ["U"] = "..-", ["V"] = "...-",
		["W"] = ".--", ["X"] = "-..-", ["Y"] = "-.--", ["Z"] = "--..",
		["["] = "-.--.", ["]"] = "-.--.-", ["_"] = "..--.-"
	}
	irc:add_command("misc", "morse", function(irc, state, channel, msg)
		return (msg:gsub(".", function(c) return morse[c:upper()] or c end))
	end, false)
	local emoticons = {"😀", "😁", "😂", "😃", "😄", "😅", "😆", "😇", "😈", "😉", "😊", "😋", "😌", "😍", "😎", "😏", "😐", "😑", "😒", "😓", "😔", "😕", "😖", "😗", "😘", "😙", "😚", "😛", "😜", "😝", "😞", "😟", "😠", "😡", "😢", "😣", "😤", "😥", "😦", "😧", "😨", "😩", "😪", "😫", "😬", "😭", "😮", "😯", "😰", "😱", "😲", "😳", "😴", "😵", "😶", "😷", "😸", "😹", "😺", "😻", "😼", "😽", "😾", "😿", "🙀"}
	irc:add_command("misc", "emoticon", function(irc, state, channel, msg)
		return emoticons[math.random(#emoticons)]
	end, false)
	local zalgo = require("utf8").escape('%x030d%x030e%x0304%x0305%x033f%x0311%x0306%x0310%x0352%x0357%x0351%x0307%x0308%x030a%x0342%x0343%x0344%x034a%x034b%x034c%x0303%x0302%x030c%x0350%x0300%x0301%x030b%x030f%x0312%x0313%x0314%x033d%x0309%x0363%x0364%x0365%x0366%x0367%x0368%x0369%x036a%x036b%x036c%x036d%x036e%x036f%x033e%x035b%x0346%x031a%x0316%x0317%x0318%x0319%x031c%x031d%x031e%x031f%x0320%x0324%x0325%x0326%x0329%x032a%x032b%x032c%x032d%x032e%x032f%x0330%x0331%x0332%x0333%x0339%x033a%x033b%x033c%x0345%x0347%x0348%x0349%x034d%x034e%x0353%x0354%x0355%x0356%x0359%x035a%x0323%x0315%x031b%x0340%x0341%x0358%x0321%x0322%x0327%x0328%x0334%x0335%x0336%x034f%x035c%x035d%x035e%x035f%x0360%x0362%x0338%x0337%x0361%x0489')
	irc:add_command("misc", "zalgo", function(irc, state, channel, msg)
		assert(#msg <= 100, "String is too long")
		local utf8 = require("utf8")
		local out = ""
		local ratio = 100 / utf8.len(msg)
		local l = utf8.len(zalgo)
		for c in utf8.gmatch(msg, ".") do
			out = out .. c
			for i = 1, ratio do
				local r = math.random(l)
				out = out .. utf8.sub(zalgo, r, r)
			end
		end
		return out
	end, false)
	irc:add_command("misc", "slap", function(irc, state, channel, nick)
		local verbs = {'slaps', 'kicks', 'destroys', 'annihilates', 'punches', 'roundhouse kicks', 'rusty hooks', 'pwns', 'owns'}
		local verb = utils.random_choice(verbs)
		local whom = utils.strip(nick)
		if irc:lower(whom) == irc:lower(irc.nick) then
			whom = irc:admin_user_mode(state.nick, "v") and "itself" or state.nick
		end
		return irc:action(verb .. " " .. whom)
	end, false)
	irc:add_command("misc", "annoy", function(irc, state, channel, msg)
		return (msg:gsub(".", function(c)
			local out = ""
			out = out .. utils.random_choice({"\002", ""}) -- bold
			out = out .. utils.random_choice({"\029", ""}) -- italics
			out = out .. utils.random_choice({"\031", ""}) -- underline
			out = out .. utils.random_choice({c:upper(), c:lower()})
			return out
		end))
	end, false)
	irc:add_command("misc", "sudo", function(irc, state, channel, command)
		assert(irc:admin_user_mode(state.nick, "o"), "User is not in the sudoers file. This incident will be reported")
		return irc:run_command(state, channel, command)
	end, true)
	irc:add_command("misc", "ip", function(irc, state, channel, domain)
		local socket = require("socket")
		return (assert(socket.dns.toip(domain)))
	end, true)
	irc:add_command("misc", "headers", function(irc, state, channel, url)
		local http = require("socket.http")
		local success, err, _, headers = pcall(http.request, {
			url = url,
			sink = utils.limited_sink({}, 1024)
		})
		assert(success, err)
		local out = {}
		for header, contents in pairs(headers) do
			out[#out + 1] = ("%s: %s"):format(header, utils.strip(contents))
		end
		return utils.escape_list(out)
	end, true)
	irc:add_command("misc", "qrcode", function(irc, state, channel, msg)
		local url = require("socket.url")
		local uri = "https://chart.googleapis.com/chart?chs=200x200&cht=qr&chl=" .. url.escape(msg)
		local shorten = irc:run_command(state, channel, "shorten " .. uri)
		return shorten or uri
	end, true)
	irc:add_command("misc", "cryptocoin_price", function(irc, state, channel, cur1, cur2)
		local https = require("ssl.https")
		local response, response_code = https.request(("https://www.cryptonator.com/api/ticker/%s-%s"):format(cur1, cur2))
		assert(response_code == 200, "Error requesting page")
		local obj, pos, err = json.decode(response)
		assert(not err, err)
		assert(obj.success, obj.error)
		return obj.ticker.price
	end, true, "string", "string")
	irc:add_command("misc", "bitcoin", function(irc, state, channel, msg)
		return irc:run_command(state, channel, "cryptocoin_price btc usd")
	end, true)
	irc:add_command("misc", "urban", function(irc, state, channel, msg)
		msg = utils.strip(msg)
		assert(msg ~= "", "Empty string")

		local http = require("socket.http")
		local url = require("socket.url")
		local uri = "http://api.urbandictionary.com/v0/define?term=" .. url.escape(msg)
		local response, response_code = http.request(uri)
		assert(response_code == 200, "Error requesting page")

		local obj, pos, err = json.decode(response:gsub("\r", "\\r"))
		assert(not err, err)
		local out = obj.list[1].definition:gsub("%s+", " ")
		if #out > 300 then
			uri = "http://www.urbandictionary.com/define.php?term=" .. url.escape(msg)
			uri = irc:run_command(state, channel, "shorten " .. uri) or uri
			out = out:sub(1, 296 - #uri) .. "... " .. uri
		end
		return out
	end, true)
	irc:add_command("misc", "lolcat", function(irc, state, channel, msg)
		msg = utils.strip(msg)
		assert(msg ~= "", "Empty string")
		
		local http = require("socket.http")
		local url = require("socket.url")
		local uri = "http://speaklolcat.com/?from=" .. url.escape(msg)
		local response, response_code = http.request(uri)
		assert(response_code == 200, "Error requesting page")
		
		local translation = response:match("<div id=\"text\">.-<p>([^>]+)</p>")
		assert(translation, "Couldn't find translation")
		
		return translation
	end, true)
	irc:add_command("misc", "screenshot", function(irc, state, channel, uri)
		local api_key = irc:get_config("page2images_key", channel)
		assert(api_key, "No api key set up")

		uri = utils.strip(uri)
		assert(uri ~= "", "Empty string")

		local http = require("socket.http")
		local url = require("socket.url")

		while true do
			local response = http.request(
				"http://api.page2images.com/restfullink" ..
				"?p2i_url=" .. url.escape(uri) ..
				"&p2i_key=" .. api_key .. 
				"&p2i_wait=25" .. -- looks like it doesn't works
				"&p2i_size=1024x768"
			)
			local obj, pos, err = json.decode(response)
			assert(not err, err)
			if obj.status == "processing" then
				socket.sleep(0.1) -- we'll try again
			elseif obj.status == "finished" then
				if obj.image_url then
					return obj.image_url
				else
					error("No image returned")
				end
			elseif obj.status == "error" then
				error(obj.msg or "Unknown error.")
			else
				error("Unknown status: " .. tostring(obj.status))
			end
		end
	end, true)
	irc:add_command("misc", "xkcd", function(irc, state, channel, msg)
		local http = require("socket.http")
		local response, response_code = http.request("https://xkcd.com/info.0.json")
		assert(response_code == 200, "Error requesting page")
		local obj, pos, err = json.decode(response)
		assert(not err, err)
		assert(obj.num, "Error requesting page")
		return "https://xkcd.com/" .. math.random(obj.num) .. "/"
	end, true)
	irc:add_command("misc", "isup", function(irc, state, channel, site)
		site = utils.strip(site)
		if not site:match("^https?://") then
			if site:find("://") then
				local protocol = utils.split(site, "://")[1] .. "://"
				error("Invalid protocol: " .. protocol)
			else
				site = "http://" .. site
			end
		end
		local http = require("socket.http")

		local t = {}
		local status, _, response_code = pcall(http.request({
			url = site,
			sink = utils.limited_sink(t, 512 * 1024)
		}))
		if response_code ~= 200 then
			return site .. " looks down from here."
		end

		if #t >= 1 then
			return site .. " looks fine to me."
		else
			return site .. " is down from here."
		end
	end, true)

	irc:add_command("misc", "download", function(irc, state, channel, url)
		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"
		local https = require("ssl.https")
		local url_parse = require("socket.url").parse

		local parsed = url_parse(url)
		assert(parsed, "Invalid url")
		assert(parsed.scheme, "Invalid url")
		assert(parsed.host, "Invalid url")
		assert(parsed.scheme == "http" or parsed.scheme == "https", "Unsupported scheme")

		url = url:gsub("#.*", "") -- stupid socket.http, it sends the fragment

		local t = {}
		local request = ({http=http, https=https})[parsed.scheme].request
		pcall(request, {
			url = url,
			sink = utils.limited_sink(t, 10 * 1024)
		})
		local s = table.concat(t)

		assert(#s <= 2048, "Max length: 2048")

		return s
	end, true)

	irc:add_command("misc", "pronunciation", function(irc, state, channel, word)
		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"

		word = utils.strip(word)

		local response, response_code = http.request("http://dictionary.cambridge.org/dictionary/american-english/" .. word)
		assert(response_code == 200, "Error requesting page")

		return (response:match('<span class="ipa">(.-)</span>'))
	end, true)

	irc:add_hook("misc", "on_cmd_privmsg", function(irc, state, channel, msg)
		if msg == irc.nick .. "!" then
			irc:privmsg(channel, state.nick .. "!")
		end
	end)
end
