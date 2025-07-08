--!strict
--!native

--// Types \\--

type table<K = any, V = any> = { [K]: V }
type array<V = any> = { V }

type ExtendedTableLibrary = {

    --[=[
        GetAllocatedArraySize

        Determines the allocated size of a Luau table's array part, not
		just the number of items currently in the table (which `#t` would give).

        @param tbl The table whose allocated size is to be determined.
        @return The allocated size of the table's array part.
    ]=]
	getAllocatedArraySize: <K, V>(tbl: table<K, V>) -> number,

	--[=[
        GetAllocatedHashSize

        Determines the allocated size of a Luau table's hash part.

        @param tbl The table to inspect.
        @return The allocated size of the table's hash part.
    ]=]
	getAllocatedHashSize: <K, V>(tbl: table<K, V>) -> number,

	 --[=[
        GetTableMemorySize

		Returns the total memory used by a table structure, including its internal 
    	allocation and structural overhead (e.g., array/hash parts), 
   		but excluding the memory used by its contents (i.e., keys and values).

        @param tbl The table to measure.
        @return An estimated memory size in bytes.
    ]=]
	getTableMemorySize: <K, V>(tbl: table<K, V>) -> number,

	--[=[
        GetTableSize

        Counts the number of elements in a table. It can be optimized for
        contiguous arrays.

        @param tbl The table to count.
        @param isContiguous? If true (default), assumes the table's array is contiguous.
				If false, iterates over all key-value pairs.
        @return The total number of elements in the table.
    ]=]
	getTableSize: <K, V>(tbl: table<K, V>, isContiguous: boolean?) -> number,

	--[=[
		MergeTables

		Recursively merging tables, combining their keys and values.
		If a key exists in more than one tables:
			- If both values are tables, they are merged recursively.
			- Otherwise, the first value is kept.

		- If `depth` is -1, it merges all nested tables without depth limit.
		- If `inPlace` is true, the first table is modified in place and returned. Otherwise, a new table is returned.

		@param inPlace? Whether to modify and return the first table instead of creating a new table (default is false).
		@param depth? The depth to merge nested tables (default is -1).
		@param ... Two or more tables to merge.
		@return A new table or modified first table with all inputs merged.
	]=]
	mergeTables: (inPlace: boolean?, depth: number?, ...table) -> (table),

	--[=[
		AccumulateTables

		Recursively combines multiple tables by summing matching numeric values and merging nested tables.

		- If a key exists in multiple tables:
			- If all values are numbers, they are added together.
			- If all values are tables, they are merged recursively.
			- If value types conflict (e.g., number vs string), an error is thrown.
		- If a key exists in only one table, that value is used.
		- Supports optional in-place modification of the first table.

		@param inPlace? If true, modifies and returns the first table.
		@param ... Two or more tables to accumulate.
		@return A new table or modified first table with all inputs accumulated.
	]=]
	accumulateTables: <K, V>(inPlace: boolean?, ...table<K, V>) -> table<K, V>,

	--[=[
		MapTable

		Creates a new table by applying a callback function to each key-value pair in the original table.

		@param tbl The table to map.
		@param callback The function to apply to each key-value pair. It receives the key and value.
		@return A new table with the results of the callback function.
	]=]
	mapTable: <K, V, U>(tbl: table<K, V>, callback: (K, V) -> U) -> table<K, U>,

	--[=[
		FilterTable

		Creates a new table containing only the key-value pairs that satisfy the given predicate function.

		@param tbl The table to filter.
		@param predicate The function to test each key-value pair. It receives the key and value.
		@param preAllocate? If true, pre-allocates the result table with the same size as the input table (default is true).

		@return A new table with only the key-value pairs that match the predicate.
	]=]
	filterTable: <K, V, U>(tbl: table<K | U, V>, predicate: (K | U, V) -> boolean, preAllocate: boolean?) -> table<U, V>,

	--[=[
		ReduceTable

		Reduces a table to a single value by applying a reducer function to each key-value pair.

		@param tbl The table to reduce.
		@param reducer The function that combines the accumulated value with each key-value pair.
			It receives the accumulated value, key, and value.
		@param initial The initial value for the reduction.
		@return The final reduced value.
	]=]
	reduceTable: <K, V, U>(tbl: table<K, V>, reducer: (U, K, V) -> U, initial: U) -> U,

	--[=[
		Match

		Finds the first key in a table that satisfies the given filter function.

		@param tbl The table to search.
		@param filter The function to test each key-value pair. It receives the key and value.
		@return The first key that matches the filter, or nil if no match is found.
	]=]
	matchTable: <K, V>(tbl: table<K, V>, filter: (K, V) -> boolean) -> K,

	--[=[
		DiffTables

		Compares two tables (`old` and `new`) and returns a breakdown of differences between them.
		Useful for detecting what has changed, been added, or removed when comparing data sets.

		@param old The original table.
		@param new The updated table to compare against the original.
		@return table A table containing:
			- `added`: table<kB, vB> — entries present in `new` but not in `old`.
			- `removed`: table<kA, vA> — entries present in `old` but not in `new`.
			- `changed`: table<kA, vA> — entries that exist in both but have different values.
	]=]
	diffTables: <kA, vA, kB, vB>(old: table<kA, vA>, new: table<kB, vB>) -> { added: table<kB, vB>, removed: table<kA, vA>, changed: table<kA, vA> },

	--[=[
        ExtendArraySize

        Extends an array by a given size.

        @param tbl The array to extend.
        @param expandSize The number of elements to add.
    ]=]
	extendArraySize: <K, V>(tbl: table<K, V>, expandSize: number) -> (),

	--[=[
		SetArraySize

		Sets the length of an array to a new size. This function can only be
		used to expand an array by nil-padding it. It cannot be used to
		truncate an array.

		@param tbl The array to resize.
		@param newSize The desired new size of the array, must be >= sizearray.
	]=]
	setArraySize: <K, V>(tbl: table<K, V>, newSize: number) -> (),

	--[=[
		TruncateArray

		Truncates an array to a specified size, removing any elements beyond that size.

		@param array The array to truncate.
		@param newSize The new size of the array. If this is less than the current size, elements will be removed.

		@return A new array with the specified size, containing the first `newSize` elements of the original array.
	]=]
	truncateArray: <T>(array: array<T>, newSize: number) -> array<T>,

    --[=[
        FlattenArray

        Flattens an array of arrays into a single, new array.

        @param src An array containing other arrays.
        @return A new, one-dimensional array.
    ]=]
	flattenArray: <T>(src: array<array<T>>) -> array<T>,

    --[=[
        CompactArray

        Compacts a sparse array into a contiguous array, removing any gaps in indices.

        @param array The array to compact. This can be a sparse array (with missing indices).
        @param allocateExactSize? If true, creates a new array with a size equal to the number of elements.
            If false or nil, use the same size as the original table, which is generally faster if exact size isn't critical.
        @return A compacted (non-sparse) version of the input array. May return the original array if it is already compact.
    ]=]
	compactArray: <T>(array: array<T>, allocateExactSize: boolean?) -> array<T>,

	--[=[
		FillArray

		Fills an array with a specified value from a start index to an end index.
		If the end index is not specified, it fills until the end of the array.

		@param array The array to fill.
		@param value The value to fill the array with.
		@param startIndex? The index to start filling from (default is 1).
		@param endIndex? The index to stop filling at (default is the length of the array).
		@param sourceArray? If provided, the function will fill the array with values from this source array,
			repeating the source if necessary. If not provided, it fills with the specified value.
	]=]
	fillArray: <T>(array: array<T>, value: T, startIndex: number?, endIndex: number?, sourceArray: array<T>?) -> (),

	--[=[
		ReverseArray

		Reverses the order of elements in an array in place.

		@param array The array to reverse.
	]=]
	reverseArray: <T>(array: array<T>) -> (),

	--[=[
		SliceArray

		Creates a new array containing a portion of the original array from startIndex to endIndex.
		If startIndex or endIndex are not provided, they default to 1 and the length of the array, respectively.

		@param array The array to slice.
		@param startIndex? The index to start slicing from (default is 1).
		@param endIndex? The index to stop slicing at (default is the length of the array).
		@return A new array containing the sliced portion.
	]=]
	sliceArray: <T>(array: array<T>, startIndex: number?, endIndex: number?) -> array<T>,

	--[=[
		ShuffleArray

		Randomly shuffles the elements of an array in place.

		@param array The array to shuffle.
	]=]
	shuffleArray: <T>(array: array<T>) -> (),

	--[=[
		ZipArray

		Combines multiple arrays into a single array of tuples (arrays), where each tuple contains
		the elements from the input arrays at the same index.

		For example, zipArray({1, 2, 3}, {"a", "b", "c"}) returns {{1, "a"}, {2, "b"}, {3, "c"}}.

		The resulting array has a length equal to the shortest of the input arrays.

		@param ...array A variable number of arrays to zip together.
		@return A new array where each element is an array containing the ith elements of the input arrays.
	]=]
	zipArray: (...array) -> array<array>,

	--[=[
		UnzipArray

		Reverses the operation of `zipArray`. Takes an array of tuples (arrays) and separates them back
		into individual arrays, one for each position in the tuples.

		For example, unzipArray({{1, "a"}, {2, "b"}, {3, "c"}}) returns {{1, 2, 3}, {"a", "b", "c"}}.

		All subarrays in the input must be of equal length.

		@param zippedArray An array of arrays (tuples) to unzip.
		@return An array of arrays, where each array contains the ith elements from the tuples in the input.
	]=]
	unzipArray: (zippedArray: array<array>) -> array<array>,

	--[=[
		GetRandomValue

		Returns a random value from the given array. If the array is empty, it returns nil.

		@param array The array to get a random value from.
		@param removeFromArray? If true, the selected value is removed from the array (default is false).
		@return A random value from the array, or nil if the array is empty.
	]=]
	getRandomValue: <T>(array: array<T>, removeFromArray: boolean?) -> T,

	--[=[
		GroupBy

		Groups the elements of a table by a specified key or property.
		The callback function receives each key-value pair and returns the grouping key.

		@param tbl The table to group.
		@param callback The function that determines the grouping key for each key-value pair.
		@return A new table where keys are the grouping keys and values are arrays of grouped items.
	]=]
	groupBy: <K, V, G>(tbl: table<K, V>, callback: (K, V) -> G) -> table<G, array<V>>,

	--[=[
        DeepCopy

        Creates a recursive, deep copy of a table.

        @param tbl The table to copy.
        @return A new table with all nested tables also copied.
    ]=]
	deepCopy: <K, V>(tbl: table<K, V>) -> table<K, V>,

    --[=[
        DeepEqual

        Recursively compares two values for equality, handling nested tables.

        @param a The first value.
        @param b The second value.
        @return True if the values are deeply equal, otherwise false.
    ]=]
	deepEqual: <A, B>(a: A, b: B) -> boolean,

    --[=[
        DeepFreeze

        Recursively freezes a table and its nested tables, making them read-only.

        @param tbl The table to freeze.
		@param layers? The number of layers to freeze. If nil, freezes all layers.
    ]=]
	deepFreeze: <K, V>(tbl: table<K, V>, layers: number?) -> table<K, V>,

	--[=[
		PrettyPrint

		Converts a table into a human-readable string format, with optional indentation.

		@param tbl The table to print.
		@param indent? The number of spaces to use for indentation (default is 2).
		@return A string representation of the table.
	]=]
	prettyPrint: <K, V>(tbl: table<K, V>, indent: number?) -> string,

	--[=[
        IsContiguousArray

        Checks if a table is an array, and if it is contiguous (i.e., has no `nil` holes from index 1 to #array).

        @param array The array to check.
        @return True if the array is contiguous, otherwise false.
    ]=]
	isContiguousArray: <T>(array: array<T>) -> boolean,

	--[=[
		IsSparseArray

		Checks if all the keys in the table are positive integer,
		and if it is sparse (i.e., has `nil` holes in the array part).

		@param array The array to check.
		@return True if the array is sparse, otherwise false.
	]=]
	isSparseArray: <T>(array: array<T>) -> boolean,
}

--// Constants \\--

local MOVE_TEMPLATE = { nil, true }
local ARRAY_REHASH_THRESHOLD = 2 ^ 12
local MAX_TABLE_SIZE = 2 ^ 26 -- Maximum size of a table in Luau

local DEFAULT_FILL_ARRAY_SIZE = 2^13 -- Size of the array used for filling operations.
local FILL_THRESHOLD = 2^11 -- Threshold for creating a fill array.
local MOVE_THRESHOLD = 2^2 + 1 -- Threshold for using `table.move` instead of a simple loop for filling arrays.

-- If true, will check the buffer's value for comparisons instead of buffer's identity.
local CHECK_BUFFER_VALUE = false

local SPECIAL_CHARACTERS = {['\a'] = '\\a', ['\b'] = '\\b', ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t', ['\v'] = '\\v', ['\0'] = '\\0'}
local LUAU_KEYWORDS = { ['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true, ['elseif'] = true, ['end'] = true, ['false'] = true, ['for'] = true, ['function'] = true, ['if'] = true, ['in'] = true, ['local'] = true, ['nil'] = true, ['not'] = true, ['or'] = true, ['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true, ['until'] = true, ['while'] = true, ['continue'] = true}

--// Functions \\--

local function deepCopy<K, V, T>(tbl: table<K, V>, valueMap: table<T, T>?): table<K, V>
	if type(tbl) == "buffer" then
		local bufferLen = buffer.len(tbl)
		local newBuffer = buffer.create(bufferLen)
		buffer.copy(tbl, 0, newBuffer)

		if valueMap then valueMap[tbl] = newBuffer end
		return newBuffer :: any
	end

	-- Create a shallow copy first, which pre-allocate and copies top-level keys and values.
	local copy: table = table.clone(tbl)
	if valueMap then
		valueMap[tbl] = copy
	else
		valueMap = {[tbl] = copy}
	end

	assert(valueMap) -- Type Reinforcement.

	-- Use a constant to avoid loading a string in every iteration.
	local TABLE_TYPE = "table"
	TABLE_TYPE = TABLE_TYPE -- Prevent folding.

	local BUFFER_TYPE = CHECK_BUFFER_VALUE and "buffer"
	BUFFER_TYPE = BUFFER_TYPE -- Prevent folding.

	-- Iterate through the table to handle nested tables.
	for k, v in tbl :: table do
		local keyType = type(k)
		local valueType = type(v)

		local shouldCloneKey = keyType == TABLE_TYPE or (CHECK_BUFFER_VALUE and keyType == BUFFER_TYPE)
		local shouldCloneValue = valueType == TABLE_TYPE or (CHECK_BUFFER_VALUE and valueType == BUFFER_TYPE)

		if shouldCloneKey then
			copy[k] = nil
			k = valueMap[k] or deepCopy(k :: K, valueMap)
			copy[k] = if shouldCloneValue then valueMap[v] or deepCopy(v) else v
		elseif shouldCloneValue then
			copy[k] = valueMap[v] or deepCopy(v)
		end
	end

	return copy :: table<K, V>
end

local function getAllocatedArraySize<K, V>(tbl: table<K, V>): number
	-- Create a probe table that preserves the original table's allocation size.
	local probeTable = table.clone(tbl)
	table.clear(probeTable) -- `table.clear` empties the table but keeps the allocated capacity.

	local ZERO_CONST = 0
	ZERO_CONST = ZERO_CONST -- Prevent folding.

	local TWO_CONST = 2
	TWO_CONST = TWO_CONST -- Prevent folding.

	-- Check if size is 0 or 1 by probing index 2.
	probeTable[2] = ZERO_CONST

	if #probeTable == ZERO_CONST then -- Size is confirmed to be either 0 or 1.
		probeTable = table.clone(tbl)
		table.move(MOVE_TEMPLATE, TWO_CONST, TWO_CONST, TWO_CONST, probeTable) -- Force expansion if size is 1.

		if #probeTable == ZERO_CONST then
			return ZERO_CONST -- The allocated size was 0.
		else
			return 1 -- The allocated size was 1.
		end
	end

	local NIL_CONST = nil
	NIL_CONST = NIL_CONST -- Prevent folding.

	-- Check if size is 2.
	probeTable[3] = ZERO_CONST
	if #probeTable == ZERO_CONST then return TWO_CONST end

	probeTable[2] = NIL_CONST

	-- Size is at least 3, begin binary search-like probing.
	local probeIndex = 3

	while true do
		-- If the probe index is large, use table.move to force array expansion, avoiding rehash's performance costs.
		if probeIndex > ARRAY_REHASH_THRESHOLD then
			table.move(probeTable, TWO_CONST, TWO_CONST, probeIndex + 1)
		else
			probeTable[probeIndex + 1] = NIL_CONST
		end
		if #probeTable == ZERO_CONST then return probeIndex end

		probeTable[probeIndex] = NIL_CONST
		probeIndex = (probeIndex - 1) * 2
		probeTable[probeIndex] = ZERO_CONST

		if #probeTable == probeIndex then continue end

		probeTable[probeIndex] = NIL_CONST
		probeIndex = probeIndex + 1
		probeTable[probeIndex] = ZERO_CONST

		if #probeTable == probeIndex then continue end

		probeTable[probeIndex] = NIL_CONST
		probeIndex = probeIndex + 1
		probeTable[probeIndex] = ZERO_CONST
	end
end

local function getAllocatedHashSize<K, V>(tbl: table<K, V>): number
	-- Clone the table to measure its hash capacity without modifying the original.
	local probeTable = table.clone(tbl)
	table.clear(probeTable) -- `table.clear` empties the table but keeps the allocated capacity.

	local ZERO_CONST = 0
	ZERO_CONST = ZERO_CONST -- Prevent folding.

	local ONE_CONST = 1
	ONE_CONST = ONE_CONST -- Prevent folding.

	local TWO_CONST = 2
	TWO_CONST = TWO_CONST -- Prevent folding.

	-- This move forces the table to have an array part, standardizing the starting state.
	table.move(MOVE_TEMPLATE, ONE_CONST, TWO_CONST, ONE_CONST, probeTable)

	-- Iterate with negative indices to probe the hash part directly.
	for i = -MAX_TABLE_SIZE, -1 do
		probeTable[i] = ONE_CONST
		if #probeTable == ZERO_CONST then return i - 1 end -- The size is found.
	end

	return MAX_TABLE_SIZE
end

local function getTableMemorySize<K, V>(tbl: table<K, V>): number
	-- Get the allocated sizes for both array and hash parts.
	local arraySize = getAllocatedArraySize(tbl)
	local hashSize = getAllocatedHashSize(tbl)

	-- Luau memory calculation based on known struct sizes.
	-- TValue (value part): 16 bytes
	-- LuaNode (TKey-TValue pair in hash): 32 bytes
	-- Table object overhead: 64 bytes (Tvalue + Table struct)
	return 64 + arraySize * 16 + hashSize * 32
end

local function getTableSize<K, V>(tbl: table<K, V>, isContiguous: boolean?): number
	if isContiguous ~= false then
		-- Start with the length operator for the contiguous array part.
		local size = #tbl
		-- Iterate through the hash part to count any remaining elements.
		for _ in next, tbl, size do
			size = size + 1
		end
		return size
	end

	-- If not contiguous, iterate through every element, which is slower but always accurate.
	local size = 0
	for _ in tbl do
		size = size + 1
	end
	return size
end

local function mergeTables(inPlace: boolean?, depth: number?, ...: table): (table)
	depth = depth or -1 -- Default depth is -1, meaning no limit on recursion depth.
	if depth == -1 then depth = math.huge end -- Convert -1 to a very large number for practical purposes.

	local result: table = inPlace and (...) or deepCopy((...))

	for i = 2, select("#", ...) do
		local tbl = select(i, ...)
		for k, v in tbl do
			local existingValue = result[k]
			if existingValue == nil then
				-- If the key does not exist in the result, simply add it.
				result[k] = deepCopy(v)
				continue
			end

			local existingType = type(existingValue)
			if existingType ~= "table" then continue end

			local valueType = type(v)
			if valueType ~= "table" then continue end

			if depth > 1 then
				result[k] = mergeTables(true, depth - 1, existingValue :: any, v)
			end
		end
	end

	return result
end

local function accumulateTables<K, V>(inPlace: boolean?, ...: table<K, V>): table<K, V>
	local result: table = inPlace and (...) or deepCopy((...))

	for i = 2, select("#", ...) do
		local tbl = select(i, ...)
		for k, v in tbl do
			local existingValue = result[k]
			if existingValue == nil then
				-- If the key does not exist in the result, simply add it.
				result[k] = deepCopy(v)
				continue
			end

			local existingType = type(existingValue)
			local valueType = type(v)

			if existingType ~= valueType then
				-- If types are different, throw an error.
				error(string.format("Cannot accumulate key '%s': conflicting types (%s vs %s)", tostring(k), existingType, valueType))
			end

			if existingType == "number" then
				-- If both values are numbers, sum them.
				result[k] = existingValue + v
			elseif existingType == "table" then
				result[k] = accumulateTables(true, existingValue :: any, v)
			end
		end
	end

	return result
end

local function mapTable<K, V, U>(tbl: table<K, V>, callback: (K, V) -> U): table<K, U>
	local result: table<K, U> = table.clone(tbl) -- Create a shallow copy of the original table to pre-allocate.

	-- Iterate through each key-value pair in the original table.
	for k, v in tbl do
		-- Apply the callback function to each key-value pair and store the result.
		result[k] = callback(k, v)
	end

	return result
end

local function filtterTable<K, V, U>(tbl: table<K, V>, predicate: (K, V) -> boolean): table<U, V>
	local result: table<U, V> = table.clone(tbl) -- Create a shallow copy of the original table to pre-allocate.

	-- Iterate through each key-value pair in the original table.
	for k, v in tbl do
		-- If the predicate returns true for this key-value pair, add it to the result.
		result[k] = if predicate(k, v) then v else nil
	end

	return result
end

local function reduceTable<K, V, U>(tbl: table<K, V>, reducer: (U, K, V) -> U, accumulator: U): U
	-- Iterate through each key-value pair in the table.
	for k, v in tbl do
		-- Apply the reducer function to the current accumulated value, key, and value.
		accumulator = reducer(accumulator, k, v)
	end

	return accumulator
end

local function matchTable<K, V>(tbl: table<K, V>, filter: (K, V) -> boolean): K?
	-- Iterate through each key-value pair in the table.
	for k, v in tbl do
		-- If the filter returns true for this key-value pair, return the key.
		if filter(k, v) then
			return k
		end
	end

	return nil -- Return nil if no matching key is found.
end

local function diffTables<kA, vA, kB, vB>(old: table<kA, vA>, new: table<kB, vB>): { added: table<kB, vB>, removed: table<kA, vA>, changed: table<kA, vA> }
	local added: table<kB, vB> = {}
	local removed: table<kA, vA> = {}
	local changed: table<kA, vA> = {}

	-- Find added and changed keys.
	for k, v in new :: table do
		if old[k] == nil then
			added[k] = v
		elseif old[k] ~= v then
			changed[k] = old[k]
		end
	end

	-- Find removed keys.
	for k in old do
		if new[k] == nil then
			removed[k] = old[k]
		end
	end

	return { added = added, removed = removed, changed = changed }
end

local function extendArraySize<T>(array: array<T>, expandSize: number)
	-- `table.move` with the same source and destination effectively extending the array length.
	local size = getAllocatedArraySize(array)
	table.move(array, size, size + expandSize, size)
end

local function setArraySize<T>(array: array<T>, newSize: number)
	-- `table.move` with the same source and destination effectively extending the array length.
	table.move(array, 1, newSize, 1)
end

local function truncateArray<T>(array: array<T>, newSize: number): array<T>
	if newSize < 0 then
		error("New size must be non-negative", 2)
	end

	local length = #array
	if newSize >= length then
		return table.clone(array)
	end

	local result: array<T> = table.create(newSize)
	table.move(array, 1, length, 1, result)

	return result
end

local function flattenArray<T>(src: array<array<T>>): array<T>
	local totalSize = 0

	-- First, calculate the total number of elements for efficient pre-allocation.
	for _, subArray in src do
		totalSize = totalSize + #subArray
	end

	-- Create the result array with the exact size needed.
	local result: array<T> = table.create(totalSize)
	local index = 1

	-- Iterate again, this time moving the sub-arrays' contents into the result array.
	for _, subArray in src do
		local subSize = #subArray
		if subSize == 0 then continue end -- Skip empty sub-arrays.

		table.move(subArray, 1, subSize, index, result)
		index = index + subSize -- Update the insertion index for the next block.
	end

	return result
end

local function compactArray<T>(array: array<T>, allocateExactSize: boolean?)
	-- Find the last numerical index in the contiguous part of the array starting from 1.
	local lastIndex: number
	for i, _ in ipairs(array) do
		lastIndex = i
	end

	-- Check if array is already compact (no extra entries past the contiguous block).
	local startIndex = next(array, lastIndex)
	if not startIndex then -- The array is already compact.
		if allocateExactSize then
			-- Return a newly sized array with only the contiguous elements.
			if lastIndex then
				local newArray = table.create(lastIndex)
				table.move(array, 1, lastIndex, 1, newArray)
				return newArray
			else
				-- The array was empty.
				return {}
			end
		else
			-- Return original array (already compact).
			return array
		end
	end

	-- The array is sparse, so we need to compact it.
	local nextIndex = startIndex + 1

	local result: array<T>
	if allocateExactSize then
		-- Count all elements to allocate a properly sized array
		local size = lastIndex or 0
		for _ in next, array, lastIndex do
			size += 1
		end
		result = table.create(size)
	else
		-- Clone and clear the array to avoid counting elements.
		result = table.clone(array)
		table.clear(result)
	end

	-- Copy initial contiguous values.
	if lastIndex then
		table.move(array, 1, lastIndex, 1, result)
	end

	local resultIndex = (lastIndex or 0) + 1

	-- Iterate through the rest of the elements in the sparse part of the array.
	-- `next` guarantees traversal in index order for the array part.
	for i, v in next, array, startIndex do
		if i ~= nextIndex then
			-- A gap in indices is found. Move the previous block of elements.
			table.move(array, startIndex, nextIndex - 1, resultIndex, result)
			resultIndex += (nextIndex - startIndex)
			startIndex = i
		end
		-- The next expected index in the current block.
		nextIndex = i + 1
	end

	-- Move the final block of elements.
	table.move(array, startIndex, nextIndex - 1, resultIndex, result)

	return result
end

local function fillArray<T>(array: array<T>, value: T, startIndex: number?, endIndex: number?, sourceArray: array<T>?)
	local from = startIndex or 1
	local to = endIndex or #array
	local fillSize = to - from + 1

	if fillSize < MOVE_THRESHOLD then
		-- If the fill size is small, fill with the specified value.
		for i = from, to do
			array[i] = value
		end
	else
		if fillSize > FILL_THRESHOLD then
			sourceArray = sourceArray or table.create(math.min(fillSize, DEFAULT_FILL_ARRAY_SIZE), value)
		end

		if sourceArray then
			-- Fill from the source array, repeating it if necessary.
			local fillArraySize = #sourceArray

			if fillSize <= fillArraySize then
				table.move(array, 1, fillSize, from, array)
			else
				local lastIndex = fillSize // fillArraySize - 1

				for i = 0, lastIndex do
					table.move(sourceArray, 1, fillArraySize, from + i * fillArraySize, array)
				end

				table.move(sourceArray, 1, fillSize % fillArraySize, from + lastIndex * fillArraySize, array)
			end
		else
			-- If the fill size is small, fill with the specified value.
			for i = from, to do
				array[i] = value
			end
		end
	end
end

local function reverseArray<T>(array: array<T>)
	local size = #array
	if size <= 1 then return end -- No need to reverse if the array is empty or has one element.

	-- Use a loop to swap elements from both ends towards the center.
	for i = 1, size // 2 do
		local j = size - i + 1
		array[i], array[j] = array[j], array[i]
	end
end

local function sliceArray<T>(array: array<T>, startIndex: number?, endIndex: number?): array<T>
	local from = startIndex or 1
	local to = endIndex or #array

	local len = #array
	if len == 0 then return {} end

	-- Handle negative indices by wrapping them around from the end of the array.
	if from < 0 then
		from = len + from + 1
	end
	if to < 0 then
		to = len + to + 1
	end

	if from > to then return {} end -- If the range is invalid, return an empty array.

	-- Create a new array and copy the specified range.
	local result: array<T> = table.create(to - from + 1)
	table.move(array, from, to, 1, result)

	return result
end

local function shuffleArray<T>(array: array<T>)
	local size = #array
	if size <= 1 then return end -- No need to shuffle if the array is empty or has one element.

	-- Use the Fisher-Yates shuffle algorithm to randomly swap elements.
	for i = size, 2, -1 do
		local j = math.random(1, i) -- Get a random index from 1 to i.
		array[i], array[j] = array[j], array[i] -- Swap elements at indices i and j.
	end
end

local function zipArray(...)
	local nArrays = select("#", ...)
	if nArrays == 0 then return {} end

	local maxLength = math.huge
	for i = 1, nArrays do
		local arr = select(i, ...)
		maxLength = math.min(maxLength, #arr)
	end

	-- Create a new array to hold the zipped result.
	local result = table.create(maxLength) :: array<array>

	-- Fill the result array with sub-arrays.
	for i = 1, maxLength do
		local subArray: array = table.create(nArrays)
		for j = 1, nArrays do
			local arr = select(j, ...)
			subArray[j] = arr[i]
		end
		result[i] = subArray
	end

	return result
end

local function unzipArray(zippedArray: array<array>)
	local size = #zippedArray
	if size == 0 then return {} end

	local nArrays = #(zippedArray[1])
	local result = table.create(nArrays) :: array<array>

	-- Fill each sub-array with the corresponding elements from the zipped array.
	for i = 1, nArrays do
		local array = table.create(size) :: array
		for j, subArray in zippedArray do
			array[j] = subArray[i]
		end
		result[i] = array
	end

	return result
end

local function getRandomValue<T>(array: array<T>, removeFromArray: boolean?): T?
	local size = #array
	if size == 0 then return nil end -- Return nil if the array is empty.

	local index = math.random(1, size) -- Get a random index from 1 to size.
	if removeFromArray then
		return table.remove(array, index) -- Remove the value at the random index.
	end

	return array[index] -- Return the value at the random index without removing it.
end

local function groupBy<K, V, G>(tbl: table<K, V>, callback: (K, V) -> G): table<G, array<V>>
	local result: table<G, array<V>> = {}

	-- Iterate through each key-value pair in the table.
	for k, v in tbl :: table do
		-- Get the grouping key using the callback function.
		local groupKey = callback(k, v)
		if groupKey == nil then
			error("Group key cannot be nil", 2)
		end

		local groupTable = result[groupKey :: G]

		-- If the group does not exist yet, create it.
		if not groupTable then
			groupTable = {}
			result[groupKey] = groupTable
		end

		-- Add the value to the corresponding group.
		table.insert(groupTable, v)
	end

	return result
end

local function deepEqual(a: any, b: any): boolean
	-- If they are physically the same or simple equal primitives, they are equal.
	if a == b then return true end

	local typeA = type(a)
	local typeB = type(b)

	-- If types are different, they can't be equal.
	if typeA ~= typeB then return false end

	if CHECK_BUFFER_VALUE and typeA == "buffer" then
		-- For buffers, compare their lengths first.
		local lenA, lenB = buffer.len(a), buffer.len(b)
		if lenA ~= lenB then return false end

		-- Compare the buffer contents as strings.
		-- Partial substring comparsion can be used if buffer are unlikely to be equal.
		return buffer.readstring(a, 0, lenA) == buffer.readstring(b, 0, lenB)
	end

	-- If types are not 'table' and they failed the initial 'a == b' check, they are not equal.
	if typeA ~= "table" then return false end

	-- Check if all keys in 'a' also exist in 'b'.
	for k, v in a do
		if b[k] == nil then return false end
	end

	-- Recursively check if values for all keys in 'b' are deeply equal to those in 'a'.
	for k, v in b do
		if not deepEqual(v, a[k]) then return false end
	end

	-- If all checks pass, the tables are deeply equal.
	return true
end

local function deepFreeze<K, V>(tbl: table<K, V>, layers: number?): table<K, V>
	-- If layers is nil, freeze all layers.
	if layers then
		if layers <= 1 then
			return table.freeze(tbl)
		end
		layers = layers - 1
	end

	local TABLE_TYPE = "table"
	TABLE_TYPE = TABLE_TYPE -- Prevent folding.

	-- Recursively freeze all nested tables first.
	for k, v in tbl do
		if type(k) == TABLE_TYPE then deepFreeze(k :: K, layers) end
		if type(v) == TABLE_TYPE then deepFreeze(v, layers) end
	end

	-- Freeze the top-level table after all its contents are frozen.
	return table.freeze(tbl)
end

local function serializeType(value: any, valueType: string): string
	if valueType == "string" then
		return '"' .. string.gsub(value, "[%c%z]", SPECIAL_CHARACTERS) .. '"'
	elseif valueType == "Instance" then
		return ((value :: any):GetFullName())
	else
		return tostring(value)
	end
end

local function prettyPrint<K, V>(tbl: table<K, V>, indent: number?): string
	local tab = string.rep(' ', indent or 2) -- Default indentation is 2 spaces.
	local ignoreTable = {}

	local function printTable(tbl: table, depthData: table, path: string): string
		local concatTbl: { string } = {}
		local cyclicData: table = ignoreTable[tbl]
		if cyclicData then
			if cyclicData[1] == depthData[1] - 1 then
				table.insert(concatTbl, '\'[Cyclic Parent ')
			else
				table.insert(concatTbl, '\'[Cyclic ')
			end

			table.insert(concatTbl, tostring(tbl))
			table.insert(concatTbl, ', path: ')
			table.insert(concatTbl, depthData[2])
			table.insert(concatTbl, ']\'')
			return table.concat(concatTbl)
		end

		local depth = depthData[1] + 1
		depthData[1] = depth-- Increment the depth for this table.
		depthData[2] = path

		ignoreTable[tbl] = depthData

		if next(tbl) == nil then
			-- table.insert(concatTbl, "{}")
			return "{}"
		end

		local padding = string.rep(tab, depth)
		local trailing = string.rep(tab, depth - 1)
		local lineTab = '\n' .. padding
		local isOrdered = true
		local nextIndex = 1

		for key, value in next, tbl do
			if isOrdered then
				if key == nextIndex then
					nextIndex += 1
				else
					isOrdered = false
				end
			end

			if isOrdered then
				local valueType = typeof(value)
				if valueType == "table" then
					value = printTable(value, table.clone(depthData), path .. "[" .. key .. "]")
				else
					value = serializeType(value, valueType)
				end

			else
				local keyType = typeof(key)
				local hasBrackets = false

				if keyType == "string" then
					key = string.gsub(key :: any, '[%c%z]', SPECIAL_CHARACTERS)
					if LUAU_KEYWORDS[key] or not string.match(key, '^[_%a][_%w]*$') then
						hasBrackets = true
						key = string.format('["%s"]', key)
					end
				else
					hasBrackets = true
					if keyType == "table" then
						key = "[" .. string.gsub(printTable(key :: any, table.clone(depthData)), '^%s*(.-)%s*$', '%1') .. "]"
					else
						key = "[" .. serializeType(key, keyType) .. "]"
					end
				end

				local valueType = typeof(value)
				if valueType == "table" then
					value = printTable(value, table.clone(depthData), path .. (hasBrackets and '' or '.') .. key)
				else
					value = serializeType(value, valueType)
				end
			end

			table.insert(concatTbl, lineTab)
			if isOrdered then
				table.insert(concatTbl, value)
			else
				table.insert(concatTbl, key :: any)
				table.insert(concatTbl, ' = ')
				table.insert(concatTbl, value)
			end
			table.insert(concatTbl, ',')
		end

		table.remove(concatTbl)
		table.insert(concatTbl, "\n")
		table.insert(concatTbl, trailing)
		table.insert(concatTbl, '}')

		return table.concat(concatTbl)
	end

	return printTable(tbl, {0, "ROOT"} :: any, "ROOT")
end

local function isContiguousArray<T>(array: array<T>): boolean
	local length = #array

	-- An empty array is contiguous only if it has no non-numeric keys.
	if length == 0 then return next(array) == nil end
	-- If there's an element right after the '#' length, it's not contiguous.
	if next(array, length) ~= nil then return false end

	local lastIndex: number

	-- `ipairs` stops at the first nil value.
	for i, _ in ipairs(array) do
		lastIndex = i + 0
	end

	-- If the last index found by ipairs matches the length, the array is contiguous.
	return lastIndex == length
end

local function isSparseArray<T>(array: array<T>): boolean
	local nextIndex, exitIndex = 1, nil

	for i, _ in next, array do
		if i ~= nextIndex then
			exitIndex = i
			break
		end
		nextIndex = i + 1
	end

	if exitIndex == nil then return false end

	for i, _ in next, array, exitIndex do
		if type(i) ~= "number" or i // 1 ~= i or i < 1 then
			return false -- Not an array
		end
	end

	return true
end

--// Return \\--

return table.freeze({
	--// Table Functions \\--
	
	mergeTables = mergeTables,
	accumulateTables = accumulateTables,
	mapTable = mapTable,
	filtterTable = filtterTable,
	reduceTable = reduceTable,
	matchTable = matchTable,
	diffTables = diffTables,
	
	groupBy = groupBy,
	deepCopy = deepCopy,
	deepEqual = deepEqual,
	deepFreeze = deepFreeze,
	
	--// Array Functions \\--
	
	extendArraySize = extendArraySize,
	setArraySize = setArraySize,
	truncateArray = truncateArray,
	flattenArray = flattenArray,
	compactArray = compactArray,
	fillArray = fillArray,
	reverseArray = reverseArray,
	sliceArray = sliceArray,
	shuffleArray = shuffleArray,
	zipArray = zipArray,
	unzipArray = unzipArray,
	
	--// Miscellaneous \\--
	
	prettyPrint = prettyPrint,
	
	isContiguousArray = isContiguousArray,
	isSparseArray = isSparseArray,
	
	getAllocatedHashSize = getAllocatedHashSize,
	getAllocatedArraySize = getAllocatedArraySize,
	getTableMemorySize = getTableMemorySize,
	getTableSize = getTableSize
}) :: ExtendedTableLibrary
