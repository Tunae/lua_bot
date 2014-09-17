return function(irc)
	irc:add_hook("n_s_n+2_s", "privmsg", function(irc, state, channel, msg)
		local n1, s1, n2, s2 = msg:match("(%d+)(.+)(%d+)(.+)")
		if n1 and n1 + 2 == n2 then
			irc:privmsg(channel, (n1 + 1) .. s1 .. (n2 + 1) .. s2)
		end
	end)
end