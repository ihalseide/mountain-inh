-- Izak's Lua utils


-- Return the number "x" clamped between the given minimum and maximum values
function clamp(x, minX, maxX)
	if x > maxX then
		return maxX
	elseif x < minX then
		return minX
	else
		return x
	end
end


-- Linear interpolation from value "a" to value "b" specified by "t".
-- To be correct, "t" should be between 0 and 1.
function mix(a, b, t)
	local t = clamp(t, 0, 1)
	return a*(1 - t) + b*t
end


-- Ease with cubic smooth interpolation from value "a" to value "b"
-- To be correct, "t" should be between 0 and 1.
function ease(a, b, t)
	return mix(a, b, cubicUnit(clamp(t, 0, 1)))
end


-- Cubic function that forms a sort of sigmoid in the unit square.
-- Such that: f(0) = 0, f(0.5) = 0.5, and f(1) = 1, and f'(0) = 0, and f'(1) = 0.
-- The solution is: f(x) = (x^2)*(3 - 2*x) = 3(x^2) - 2(x^3)
function cubicUnit(x)
	return x*x*(3 - 2*x)
end


-- GLSL smoothstep function of "x" between "edge1" and "edge2"
-- https://docs.gl/sl4/smoothstep
function smoothstep(edge1, edge2, x)
	if edge1 >= edge2 then
		error("function `smoothstep`: result is undefined if `edge1` >= `edge2`", 2)
	end
	local t = clamp((x - edge1) / (edge2 - edge1), 0, 1)
	return cubicUnit(t)
end


-- Treat "b" as a boolean value and convert it to 1 for true and 0 for false.
function boolToInt(b)
	if b then return 1
	else return 0 end
end


-- Generates a step function, by comparing "x" to "edge".
-- Parameters "edge" and "x" can either be tables or numbers, but must both be the same type.
-- Returns either a single number or an array of numbers.
function step(edge, x)
	-- helper function 
	local function step_1(edge_1, x_1) return boolToInt(x_1 < edge_1) end

	if type(edge) ~= type(x) then
		error("function `step`: `edge` and `x` should be the same type", 2)
	elseif type(edge) == "number" then
		return step1(edge, x)
	elseif type(edge) == "table" then
		if #edge ~= #x then
			error("function `step`: parameters should have the same length", 2)
		end
		local result = {}
		for i = 1, #edge do
			result[i] = step_1(edge[i], x[i])
		end
		return result
	else
		error("function `step`: `edge` and `x` should both be numbers or tables")
	end
end


-- Escape special characters in a string
function escape(s)
	if type(s) ~= "string" then
		error("function `escape` is only defined for strings")
	end
	
	local t = {}
	for c in s:gmatch"." do
		if c == "\n" then t[1+#t] = "\\n"      -- literal \n
		elseif c == "\r" then t[1+#t] = "\\r"  -- literal \r
		elseif c == "\t" then t[1+#t] = "\\t"  -- literal \t
		elseif c == "\"" then t[1+#t] = "\\\"" -- literal \"
		elseif c == "\\" then t[1+#t] = "\\\\" -- literal \\
		elseif c == "\'" then t[1+#t] = "\\\'" -- literal \'
		else t[1+#t] = c
		end
	end
	return table.concat(t)
end


-- See a string representation of "x".
-- Level is the number of levels of recursion to allow when presenting a table
function quote(x, level)
	local next_level = level
	if next_level then
		next_level = level - 1
	end	
	
	if type(x) == "string" then
		-- Make strings appear the same as in literal form
		return table.concat({"\"", escape(x), "\""})
	elseif type(x) == "table" then
		local m = getmetatable(x)
		if (level and level <= 0) or (m and m.__tostring) then
			-- End of recursion, or the table has a custom tostring()
			return tostring(x)
		else
			-- Recursively print a whole table
			local t = {}
			for k, v in pairs(x) do
				if type(k) == "string" and k:match("^%w+$") then
					-- Key can be unquoted because it is a valid identifier word
					t[1+#t] = k .. " = " .. quote(v, next_level)
				else
					t[1+#t] = "[" .. quote(k, next_level) .. "] = " .. quote(v, next_level)
				end
			end
			return table.concat({"{", table.concat(t, ", "), "}"})
		end
	else
		return tostring(x)
	end
end