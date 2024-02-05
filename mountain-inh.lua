--[[
MOUNTAIN-INH.LUA
Izak Nathanael Halseide's Lua utilities.
"Build your mountain."

USAGE:
Copy this file into a Lua project, remove unwanted dependencies, and require() it.

CHANGE LOG:

-- Update [ 2024-02-05 3:00PM ]
    Turned this file into a Lua module.
	Started keeping track of updates.

]]


local M = {
	__version = 'mountain-inh.lua 2024-02-05 3:00PM'
}


-- Convert a list (table) to a string
local function listToString(T)
	return table.concat({ '{', table.concat(T, ', '), '}' }, '')
	-- alternative:
	--return '{' .. table.concat(T, ', ') .. '}'
end


-- Count the number of items (length) in a table.
local function keyCount(table)
	local n = 0
	for _, _ in pairs(table) do
		n = n + 1
	end
	return n
end


-- Return the number "x" clamped between the given minimum and maximum values (inclusive)
local function clamp(x, x1, x2)
	local hi = math.max(x1, x2)
	local lo = math.min(x1, x2)
	return math.min(hi, math.max(lo, x))
end


-- Linear interpolation from value "a" to value "b" specified by "t".
-- Usually, "t" should be between 0 and 1.
local function mix(a, b, t)
	return a * (1 - t) + b * t
end


-- Re-mix `x` from an input range of `in1` to `in2` to an output range of `out1` to `out2`.
-- For example: remix(x, 0, 1, 3, 8) will map `x`
--   from between 0 and 1 to be proportionally somewhere between 3 and 8.
-- Note: This function may return values outside of the output range
--   if `x` is already outside of the input range.
-- This function copies the functionality of Processing's `map` function
-- [https://processing.org/reference/map_.html]
local function remix(x, in1, in2, out1, out2)
	return out1 + ((x - in1) * (out2 - out1) / (in2 - in1))
end


-- Note: Equivalent to `remix`, except that `x` will be kept inside the output range.
local function remixClamped(in1, in2, out1, out2, x)
	local y = remix(x, in1, in2, out2, out2)
	if out1 < out2 then
		return clamp(y, out1, out2)
	else
		return clamp(y, out2, out1)
	end
end


-- Ease with cubic smooth interpolation from value "a" to value "b"
-- Usually, "t" should be between 0 and 1.
local function ease(a, b, t)
	return mix(a, b, M.cubicUnit(clamp(t, 0, 1)))
end


-- Cubic function that forms a sort of sigmoid in the unit square.
-- Such that: f(0) = 0, f(0.5) = 0.5, and f(1) = 1, and f'(0) = 0, and f'(1) = 0.
-- The solution is: f(x) = (x^2)*(3 - 2*x) = 3*(x^2) - 2*(x^3)
local function cubicUnit(x)
	return x * x * (3 - 2 * x)
end


-- GLSL smoothstep function of "x" between "edge1" and "edge2"
-- https://docs.gl/sl4/smoothstep
local function smoothstep(edge1, edge2, x)
	if edge1 >= edge2 then
		error("function `smoothstep`: result is undefined if `edge1` >= `edge2`", 2)
	end
	local t = clamp((x - edge1) / (edge2 - edge1), 0, 1)
	return cubicUnit(t)
end


-- Treat "b" as a boolean value and convert it to 1 for true and 0 for false.
-- Only 'nil' and 'false' map to 0, and everything else maps to 1.
local function boolToInt(b)
	return b and 1 or 0
end


-- helper function for step()
local function step_1(edge_1, x_1)
	return boolToInt(x_1 < edge_1)
end


-- Generates a step function, by comparing "x" to "edge".
-- Parameters "edge" and "x" can either be tables or numbers, but must both be the same type.
-- Returns either a single number or an array of numbers.
local function step(edge, x)
	if type(edge) ~= type(x) then
		error("function `step`: `edge` and `x` should be the same type", 2)
	elseif type(edge) == "number" then
		return step_1(edge, x)
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
local function escape(s)
	return string.format("%q", s)
	--[[
	if type(s) ~= "string" then
		error("function `escape` is only defined for strings")
	end
	
	local t = {}
	for c in s:gmatch"." do
		if c == "\n" then t[1 + #t] = "\\n"      -- literal \n
		elseif c == "\r" then t[1 + #t] = "\\r"  -- literal \r
		elseif c == "\t" then t[1 + #t] = "\\t"  -- literal \t
		elseif c == "\"" then t[1 + #t] = "\\\"" -- literal \"
		elseif c == "\\" then t[1 + #t] = "\\\\" -- literal \\
		elseif c == "\'" then t[1 + #t] = "\\\'" -- literal \'
		else t[1 + #t] = c
		end
	end
	return table.concat(t)
	--]]
end


-- Return if a string needs to be quoted because it has non-word characters or is a keyword.
-- Helper function for quote().
local function needsQuote(k)
	local luaKeywords = {
		"and", "break", "do", "else", "elseif", "end", "false", "for", "function",
		"if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true",
		"until", "while"
	}
	return type(k) ~= "string" or (not k:match("^%w+$")) or M.member(k, luaKeywords)
end


-- See a string representation of "x".
-- The 'level' is the number of levels of recursion to allow when presenting a table.
-- If `level` is omitted, there will be no limit.
local function quote(x, level)
	local next_level = level
	if next_level then
		next_level = level - 1
	end

	if type(x) == "string" then
		-- Make strings appear the same as in literal form
		return escape(x)
	elseif type(x) == "table" then
		local m = getmetatable(x)
		if (level and level <= 0) or (m and m.__tostring) then
			-- End of recursion, or the table has a custom tostring()
			return tostring(x)
		else
			-- Recursively print a whole table
			local t = {}
			for k, v in pairs(x) do
				if not needsQuote(k) then
					-- Key can be unquoted because it is a valid identifier word
					-- (this doesn't check for Lua keywords, though!)
					t[1 + #t] = k .. " = " .. quote(v, next_level)
				else
					-- Key is such that it must be quoted
					t[1 + #t] = "[" .. quote(k, next_level) .. "] = " .. quote(v, next_level)
				end
			end
			return table.concat({ "{", table.concat(t, ", "), "}" }) -- (join)
		end
	else
		return tostring(x)
	end
end


-- Queue object
local Queue = {}
Queue.mt = {}

function Queue.new()
	local obj = { first = 0, last = -1 }
	return setmetatable(obj, Queue.mt)
end

function Queue:isEmpty()
	return self.last < self.first
end

function Queue:put(value)
	local last = self.last + 1
	self.last = last
	self[last] = value
end

function Queue:pop()
	local first = self.first
	if first > self.last then
		--error("Queue is empty")
		return nil
	end
	local value = self[first]
	self[first] = nil -- to allow garbage collection
	self.first = first + 1

	-- Indices can reset if empty
	if Queue.isEmpty(self) then
		self.first = 0
		self.last = -1
	end

	return value
end

-- Sparse 2D grid object.
-- Used for indexing a table with a key that is a 2-element integer list.
-- Example:
--   local grid = Sparse2D.new()
--   grid[{1, 2}] = 'Value here'
--   print(grid[{1, 2}]) --> 'Value here'
Sparse2D = {}
Sparse2D.mt = {}

-- Create a new Sparse2D object (`t` is optional)
function Sparse2D.new(t)
	return setmetatable((t or {}), Sparse2D.mt)
end

-- Lookup table with a keys being defined as equal if the 2 elements are equal
-- If the key is not present, fall back on rawget()
Sparse2D.mt.__index = function(table, key)
	if not type(key) == 'table' then return nil end
	if #key < 2 then return nil end
	local a, b = key[1], key[2]
	if not M.isInteger(a) then return nil end
	if not M.isInteger(b) then return nil end
	for k, v in pairs(table) do
		if k[1] == a and k[2] == b then
			return v
		end
	end
	return nil
end

Sparse2D.mt.__newindex = function(table, key, val)
	if not type(key) == 'table' then return nil end
	if #key < 2 then return nil end
	local a, b = key[1], key[2]
	if not M.isInteger(a) then return nil end
	if not M.isInteger(b) then return nil end
	for k, v in pairs(table) do
		if k[1] == a and k[2] == b then
			-- This key already exists, so update the value
			rawset(table, k, val)
			return
		end
	end
	-- This key does not exist, so add it
	rawset(table, key, val)
end

-- Check if a table contains a value as a member.
-- If the `item` is a table, this function will only check for reference equality (normal for Lua).
local function member(item, aTable)
	if type(aTable) ~= 'table' then
		error('member: argument #2 should be table', 2)
	end
	for _, val in pairs(aTable) do
		if item == val then return true end
	end
	return false
end


-- Check if a value `x` is an integer number.
local function isInteger(x)
	-- Lua numbers have a fractional part, and for integers modulo 1 is 0.
	return (type(x) == 'number') and (x % 1) == 0
end


-- Reverse the order of elements in a list (table) `t`.
local function reverseTable(t)
	local result = {}
	local len = #t
	for i, x in ipairs(t) do
		result[len - i + 1] = x
	end
	return result
end


-- Returns true if `n` is prime, and false if it is composite.
-- The `n` should be non-negative.
local function isPrime(n)
	assert(isInteger(n), "isPrime: argument #1 should be an integer")
	assert(n >= 0, "isPrime: argument #1 should be non-negative")
	local limit = 1 + math.floor(math.sqrt(n))
	if n == 2 then
		return true
	end
	for factor = 2, limit do
		if n % factor == 0 then
			return false, factor
		end
	end
	return n >= 2
end


-- Returns a table of 1's and 0's to represent N in a binary string.
-- (I originally created this function for powMod(), but it is not used there and is useful on its own).
local function toBinary(n)
	if not isInteger(n) then return end
	if n < 0 then return end
	if n == 0 then return '0' end
	local result = {}
	local i = 1
	while n > 0 do
		result[i] = n % 2
		n = math.floor(n / 2)
		i = i + 1
	end
	return reverseTable(result)
end


-- Square-and-multiply algorithm to compute the value of:
-- B^E mod M where B is the base, E is the positive exponent, and M is the modulus.
-- This function is only for non-negative exponents (including 0).
local function powModNonNegative(base, exponent, modulus)
	if (not isInteger(base)) or base <= 0 then return end
	if (not isInteger(exponent)) or exponent < 0 then return end
	if (not isInteger(modulus)) or modulus <= 0 then return end
	local a, b = base, 1
	while exponent > 0 do
		if exponent % 2 == 1 then
			b = (a * b) % modulus
		end
		a = (a * a) % modulus
		exponent = math.floor(exponent / 2)
	end
	return b
end


-- POWer MODulo.
-- Compute B^E mod M where B is the base, E is the exponent, and M is the modulus.
-- Works for negative exponents as well.
local function powMod(base, exponent, modulus)
	if exponent < 0 then
		return M.inverseMod(powModNonNegative(base, -exponent, modulus), modulus)
	else
		return powModNonNegative(base, exponent, modulus)
	end
end


-- POWer MODulo for a modulus that may or may not be prime.
-- Compute B^E mod M where B is the base, E is the exponent, and M is the modulus.
-- This function assumes that `modulusIsPrime` is accurate.
local function powModPrime(base, exponent, modulus, modulusIsPrime)
	if modulusIsPrime then
		-- Using Fermat's little theorem, we know that we can reduce the exponent this way
		-- when the modulus is prime.
		exponent = exponent % (modulus - 1)
	end
	return powMod(base, exponent, modulus)
end


-- Floor division (implements C-like integer division for Lua)
local function floorDiv(dividend, divisor)
	return math.floor(dividend / divisor)
end


-- Find the Greatest Common Divisor of two integers `a` and `b`.
-- Return (g, u, v) for the solution of:
--   a*u + b*v = gcd(a, b)
-- (This is the extended Euclidean algorithm).
local function gcd(a, b)
	if (not isInteger(a)) or a < 0 then return end
	if (not isInteger(b)) or b < 0 then return end
	local u, g, x, y = 1, a, 0, b
	if b == 0 then
		return a, 1, 0
	end
	while y ~= 0 do
		local q = floorDiv(g, y)
		local t = g % y
		local s = u - q * x
		u = x
		g = y
		x = s
		y = t
	end
	local v = (g - a * u) / b
	return g, u, v
end


-- Find multiplicative inverse of X mod M
local function inverseMod(x, modulus)
	local g, u, v = gcd(x, modulus)
	if g ~= 1 then
		-- No inverse
		return nil
	end
	-- Make sure result is positive
	while u < 0 do
		u = u + modulus
	end
	return u
end


-- Check if two tables are equal.
-- This is shallow, non deep: i.e. does not compare elements which are tables.
local function tableEqual(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then
		return false
	end
	-- Same table reference?
	if a == b then
		return true
	end
	-- Different array length?
	if #a ~= #b then
		return false
	end
	-- Different key count?
	if keyCount(a) ~= keyCount(b) then
		return false
	end
	-- Different elements?
	for k, v in pairs(a) do
		if b[k] ~= v then
			return false
		end
	end
	return true
end

-- Check if a 2D point (px, py) is inside a rectangle starting at (rx, ry) with size (rw, rh).
local function isPointInsideRect(px, py, rx, ry, rw, rh)
	return rx <= px and px <= rx + rw and ry <= py and py <= ry + rh
end

-- Convert seconds to hours, minutes, and seconds.
local function secondsToHMS(seconds)
	local h = math.floor(seconds / 3600)
	seconds = math.floor(seconds - h * 3600)
	assert(0 <= seconds and seconds < 3600)
	local m = math.floor(seconds / 60)
	seconds = math.floor(seconds - m * 60)
	assert(0 <= m and m < 60)
	local s = seconds
	assert(0 <= s and s < 60)
	return h, m, s
end

-- Export the module
M.listToString = listToString
M.keyCount = keyCount
M.clamp = clamp
M.mix = mix
M.remix = remix
M.remixClamped = remixClamped
M.ease = ease
M.cubicUnit = cubicUnit
M.smoothstep = smoothstep
M.boolToInt = boolToInt
M.step = step
M.escape = escape
M.needsQuote = needsQuote
M.quote = quote
M.Queue = Queue
M.Sparse2D = Sparse2D
M.member = member
M.isInteger = isInteger
M.reverseTable = reverseTable
M.isPrime = isPrime
M.toBinary = toBinary
M.powModNonNegative = powModNonNegative
M.powMod = powMod
M.powModPrime = powModPrime
M.floorDiv = floorDiv
M.gcd = gcd
M.inverseMod = inverseMod
M.tableEqual = tableEqual
M.isPointInsideRect = isPointInsideRect
M.secondsToHMS = secondsToHMS
return M