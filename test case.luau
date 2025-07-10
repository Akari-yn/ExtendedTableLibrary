--// Import \\--

local ExtendedTableLibrary = require("./ExtendedTableLibrary")

--// Test Cases \\--

local deepEqual = ExtendedTableLibrary.deepEqual

local TestCases = {

	[1] = {
		Name = "Memory & Size Utilities",

		TestCases = {
			-- getAllocatedArraySize tests
			{
				Name = "getAllocatedArraySize",
				Function = function()
					for i = 0, 2 ^ 13 do
						local testArray = table.create(i)
						local size = ExtendedTableLibrary.getAllocatedArraySize(testArray)

						assert(size == i, `getAllocatedArraySize failed for size: {i} (expected {i}, got {size})`)
					end
				end,
			},

			-- getAllocatedHashSize tests
			{
				Name = "getAllocatedHashSize",

				TestCases = {
					{
						Name = "getAllocatedHashSize on empty table",
						Input = { {} },
						Expected = 0,
						Function = ExtendedTableLibrary.getAllocatedHashSize,
					},

					{
						Name = "getAllocatedHashSize with n elements",
						Function = function()
							for i = 1, 2 ^ 13 do
								local hashTable = {}
								for j = 1, i do
									hashTable[-j] = j
								end

								local expectedSize = 2 ^ math.ceil(math.log(i, 2)) -- Size is always a power of 2
								local receivedSize = ExtendedTableLibrary.getAllocatedHashSize(hashTable)

								assert(
									expectedSize == receivedSize,
									`getAllocatedHashSize failed for size: {i} (expected {expectedSize}, got {receivedSize})`
								)
							end
						end,
					},
				},
			},

			-- getTableMemorySize tests
			{
				Name = "getTableMemorySize",

				TestCases = {
					{
						Name = "getTableMemorySize on empty table",
						Input = { {} },
						Expected = 64,
						Function = ExtendedTableLibrary.getTableMemorySize,
					},

					{
						Name = "getTableMemorySize on array with 100 elements",
						Input = { table.create(100) },
						Expected = 64 + 100 * 16,
						Function = ExtendedTableLibrary.getTableMemorySize,
					},

					{
						Name = "getTableMemorySize on complex table",
						Input = { { 1, 2, 3, a = 1, b = "test", c = { d = 2 } }, true},
						Expected = 16 + 48 -- tvalue + table struct
							+ (16 * 3) -- 3 array elements
							+ (16 + 32) -- "a" key
							+ 16 -- and value
							+ (16 + 32) -- "b" key
							+ (16 + 32) -- and value
							+ (16 + 32) -- "c" key
							+ (16 + ( -- and value
								48 -- nested table struct
								+ (16 + 32) -- "d" key
								+ 16 -- and value
								))
							+ 32 -- empty hash portion
						,
						Function = ExtendedTableLibrary.getTableMemorySize,
					},
				},
			},

			-- getTableSize tests
			{
				Name = "getTableSize",
				TestCases = {
					{
						Name = "getTableSize on empty table",
						Input = { table.create(100) },
						Expected = 0,
						Function = ExtendedTableLibrary.getTableSize,
					},
					{
						Name = "getTableSize on hash table with 10 elements",
						Input = { { a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8, i = 9, j = 10 } },
						Expected = 10,
						Function = ExtendedTableLibrary.getTableSize,
					},

					{
						Name = "getTableSize on array with 100 elements",
						Input = { table.create(100, 1) },
						Expected = 100,
						Function = ExtendedTableLibrary.getTableSize,
					},

					{
						Name = "getTableSize on mixed table",
						Input = { { false, true, {}, nil, 5, a = 1, b = "test", c = false }, false},
						Expected = 7,
						Function = ExtendedTableLibrary.getTableSize,
					},
				},
			},
		},
	},

	[2] = {
		Name = "Table Transformation",

		TestCases = {
			-- mergeTables tests
			{
				Name = "mergeTables",
				TestCases = {
					{
						Name = "Basic merge without depth limit",
						Function = function()
							local t1 = { a = 1, b = { x = 1 } }
							local t2 = { b = { y = 2 }, c = 3 }
							local result = ExtendedTableLibrary.mergeTables(false, -1, t1, t2)
							local expected = { a = 1, b = { x = 1, y = 2 }, c = 3 }
							assert(deepEqual(result, expected), "Basic merge failed")
						end,
					},
					{
						Name = "In-place merge",
						Function = function()
							local t1 = { a = 1, b = 2 }
							local t2 = { c = 3, d = 4 }
							local result = ExtendedTableLibrary.mergeTables(true, -1, t1, t2)
							assert(result == t1, "In-place merge should return first table")
							assert(deepEqual(t1, { a = 1, b = 2, c = 3, d = 4 }), "In-place merge content failed")
						end,
					},
					{
						Name = "Depth-limited merge",
						Function = function()
							local t1 = { a = { b = { c = 1 } } }
							local t2 = { a = { b = { d = 2 }, e = 3 } }
							local result = ExtendedTableLibrary.mergeTables(false, 1, t1, t2)
							local expected = { a = { b = { c = 1 }, e = 3 } }
							assert(deepEqual(result, expected), "Depth-limited merge failed")
						end,
					},
					{
						Name = "Conflicting values (first wins)",
						Function = function()
							local t1 = { a = 1, b = "first" }
							local t2 = { a = 2, b = "second" }
							local result = ExtendedTableLibrary.mergeTables(false, -1, t1, t2)
							local expected = { a = 1, b = "first" }
							assert(deepEqual(result, expected), "Conflicting values should keep first")
						end,
					},
				},
			},

			-- mergeTablesWith tests
			{
				Name = "mergeTablesWith",
				TestCases = {
					{
						Name = "Basic merge with resolver",
						Function = function()
							local resolver = function(key, val1, val2)
								return val1 + val2
							end
							local t1 = { a = 1, b = 2 }
							local t2 = { a = 3, c = 4 }
							local result = ExtendedTableLibrary.mergeTablesWith(false, -1, resolver, t1, t2)
							local expected = { a = 4, b = 2, c = 4 }
							assert(deepEqual(result, expected), "Merge with resolver failed")
						end,
					},
					{
						Name = "String concatenation resolver",
						Function = function()
							local resolver = function(key, val1, val2)
								return val1 .. val2
							end
							local t1 = { name = "John", surname = "Doe" }
							local t2 = { name = "ny", title = "Mr." }
							local result = ExtendedTableLibrary.mergeTablesWith(false, -1, resolver, t1, t2)
							local expected = { name = "Johnny", surname = "Doe", title = "Mr." }
							assert(deepEqual(result, expected), "String concatenation resolver failed")
						end,
					},
					{
						Name = "In-place merge with resolver",
						Function = function()
							local resolver = function(key, val1, val2)
								return val1 * val2
							end
							local t1 = { a = 2, b = 3 }
							local t2 = { a = 4, c = 5 }
							local result = ExtendedTableLibrary.mergeTablesWith(true, -1, resolver, t1, t2)
							assert(result == t1, "In-place merge should return first table")
							assert(deepEqual(t1, { a = 8, b = 3, c = 5 }), "In-place merge with resolver failed")
						end,
					},
				},
			},

			-- accumulateTables tests
			{
				Name = "accumulateTables",
				TestCases = {
					{
						Name = "Basic number accumulation",
						Function = function()
							local t1 = { a = 1, b = 2, c = 3 }
							local t2 = { a = 4, b = 5, d = 6 }
							local t3 = { a = 7, c = 8, e = 9 }
							local result = ExtendedTableLibrary.accumulateTables(false, t1, t2, t3)
							local expected = { a = 12, b = 7, c = 11, d = 6, e = 9 }
							assert(deepEqual(result, expected), "Number accumulation failed")
						end,
					},
					{
						Name = "Nested table accumulation",
						Function = function()
							local t1 = { stats = { hp = 100, mp = 50 } }
							local t2 = { stats = { hp = 20, sp = 30 } }
							local result = ExtendedTableLibrary.accumulateTables(false, t1, t2)
							local expected = { stats = { hp = 120, mp = 50, sp = 30 } }
							assert(deepEqual(result, expected), "Nested table accumulation failed")
						end,
					},
					{
						Name = "In-place accumulation",
						Function = function()
							local t1 = { a = 1, b = 2 }
							local t2 = { a = 3, c = 4 }
							local result = ExtendedTableLibrary.accumulateTables(true, t1, t2)
							assert(result == t1, "In-place accumulation should return first table")
							assert(deepEqual(t1, { a = 4, b = 2, c = 4 }), "In-place accumulation failed")
						end,
					},
					{
						Name = "Type conflict error",
						Function = function()
							local t1 = { a = 1 }
							local t2 = { a = "string" }
							local success = pcall(ExtendedTableLibrary.accumulateTables, false, t1, t2)
							assert(not success, "Should throw error on type conflict")
						end,
					},
				},
			},

			-- diffTables tests
			{
				Name = "diffTables",
				TestCases = {
					{
						Name = "Basic table diff",
						Function = function()
							local old = { a = 1, b = 2, c = 3 }
							local new = { a = 1, b = 4, d = 5 }
							local result = ExtendedTableLibrary.diffTables(old, new)

							assert(deepEqual(result.added, { d = 5 }), "Added items incorrect")
							assert(deepEqual(result.removed, { c = 3 }), "Removed items incorrect")
							assert(deepEqual(result.changed, { b = 4 }), "Changed items incorrect")
						end,
					},
					{
						Name = "No differences",
						Function = function()
							local old = { a = 1, b = 2 }
							local new = { a = 1, b = 2 }
							local result = ExtendedTableLibrary.diffTables(old, new)

							assert(deepEqual(result.added, {}), "Should have no added items")
							assert(deepEqual(result.removed, {}), "Should have no removed items")
							assert(deepEqual(result.changed, {}), "Should have no changed items")
						end,
					},
					{
						Name = "Completely different tables",
						Function = function()
							local old = { a = 1, b = 2 }
							local new = { c = 3, d = 4 }
							local result = ExtendedTableLibrary.diffTables(old, new)

							assert(deepEqual(result.added, { c = 3, d = 4 }), "Added items incorrect")
							assert(deepEqual(result.removed, { a = 1, b = 2 }), "Removed items incorrect")
							assert(deepEqual(result.changed, {}), "Should have no changed items")
						end,
					},
				},
			},

			-- syncTable tests
			{
				Name = "syncTable",
				TestCases = {
					{
						Name = "Basic sync operation",
						Function = function()
							local src = { a = 1, b = 2, c = 3 }
							local target = { a = 10, d = 40 }
							local result = ExtendedTableLibrary.syncTable(src, target)

							assert(result == target, "Should return target table")
							assert(deepEqual(target, { a = 10, b = 2, c = 3 }), "Sync operation failed")
						end,
					},
					{
						Name = "Sync with empty source",
						Function = function()
							local src = {}
							local target = { a = 1, b = 2 }
							ExtendedTableLibrary.syncTable(src, target)

							assert(deepEqual(target, {}), "Target should be empty after sync with empty source")
						end,
					},
					{
						Name = "Sync with empty target",
						Function = function()
							local src = { a = 1, b = 2 }
							local target = {}
							ExtendedTableLibrary.syncTable(src, target)

							assert(deepEqual(target, { a = 1, b = 2 }), "Target should match source after sync")
						end,
					},
				},
			},

			-- mapTable tests
			{
				Name = "mapTable",
				TestCases = {
					{
						Name = "Map values to their squares",
						Function = function()
							local tbl = { a = 2, b = 3, c = 4 }
							local result = ExtendedTableLibrary.mapTable(tbl, function(key, value)
								return value * value
							end)
							local expected = { a = 4, b = 9, c = 16 }
							assert(deepEqual(result, expected), "Map to squares failed")
						end,
					},
					{
						Name = "Map keys and values to strings",
						Function = function()
							local tbl = { 1, 2, 3 }
							local result = ExtendedTableLibrary.mapTable(tbl, function(key, value)
								return `{key}:{value}`
							end)
							local expected = { "1:1", "2:2", "3:3" }
							assert(deepEqual(result, expected), "Map to strings failed")
						end,
					},
					{
						Name = "Map empty table",
						Function = function()
							local tbl = {}
							local result = ExtendedTableLibrary.mapTable(tbl, function(key, value: number)
								return value * 2
							end)
							assert(deepEqual(result, {}), "Empty table map should return empty table")
						end,
					},
					{
						Name = "Map with mixed key types",
						Function = function()
							local tbl = { a = 1, [2] = "two", [true] = false }
							local result = ExtendedTableLibrary.mapTable(tbl, function(key, value)
								return tostring(value) .. "_mapped"
							end)
							local expected = { a = "1_mapped", [2] = "two_mapped", [true] = "false_mapped" }
							assert(deepEqual(result, expected), "Mixed key types map failed")
						end,
					},
				},
			},

			-- filterTable tests
			{
				Name = "filterTable",
				TestCases = {
					{
						Name = "Filter even numbers",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3, d = 4, e = 5 }
							local result = ExtendedTableLibrary.filterTable(tbl, function(key, value: number)
								return value % 2 == 0
							end)
							local expected = { b = 2, d = 4 }
							assert(deepEqual(result, expected), "Filter even numbers failed")
						end,
					},
					{
						Name = "Filter by key pattern",
						Function = function()
							local tbl = { apple = 1, banana = 2, apricot = 3, cherry = 4 }
							local result = ExtendedTableLibrary.filterTable(tbl, function(key, value)
								return string.sub(key, 1, 2) == "ap"
							end)
							local expected = { apple = 1, apricot = 3 }
							assert(deepEqual(result, expected), "Filter by key pattern failed")
						end,
					},
					{
						Name = "Filter with no matches",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3 }
							local result = ExtendedTableLibrary.filterTable(tbl, function(key, value)
								return value > 10
							end)
							assert(deepEqual(result, {}), "Filter with no matches should return empty table")
						end,
					},
					{
						Name = "Filter all elements match",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3 }
							local result = ExtendedTableLibrary.filterTable(tbl, function(key, value)
								return value > 0
							end)
							assert(deepEqual(result, tbl), "Filter where all match should return identical table")
						end,
					},
					{
						Name = "Filter with preAllocate false",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3, d = 4 }
							local result = ExtendedTableLibrary.filterTable(tbl, function(key, value: number)
								return value % 2 == 0
							end, false)
							local expected = { b = 2, d = 4 }
							assert(deepEqual(result, expected), "Filter with preAllocate false failed")
						end,
					},
				},
			},

			-- reduceTable tests
			{
				Name = "reduceTable",
				TestCases = {
					{
						Name = "Sum all values",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3, d = 4 }
							local result = ExtendedTableLibrary.reduceTable(tbl, function(acc, key, value)
								return acc + value
							end, 0)
							assert(result == 10, `Sum reduction failed: expected 10, got {result}`)
						end,
					},
					{
						Name = "Concatenate string values",
						Function = function()
							local tbl = { first = "Hello", second = " ", third = "World" }
							local result = ExtendedTableLibrary.reduceTable(tbl, function(acc, key, value)
								return acc .. value
							end, "")
							-- Note: Order might vary due to table iteration
							local hasHello = string.find(result, "Hello") ~= nil
							local hasWorld = string.find(result, "World") ~= nil
							local hasSpace = string.find(result, " ") ~= nil
							assert(hasHello and hasWorld and hasSpace, "String concatenation reduction failed")
						end,
					},
					{
						Name = "Find maximum value",
						Function = function()
							local tbl = { a = 5, b = 12, c = 3, d = 8 }
							local result = ExtendedTableLibrary.reduceTable(tbl, function(acc, key, value)
								return math.max(acc, value)
							end, 0)
							assert(result == 12, `Max reduction failed: expected 12, got {result}`)
						end,
					},
					{
						Name = "Count elements",
						Function = function()
							local tbl = { a = "apple", b = "banana", c = "cherry" }
							local result = ExtendedTableLibrary.reduceTable(tbl, function(acc: number, key, value)
								return acc + 1
							end, 0)
							assert(result == 3, `Count reduction failed: expected 3, got {result}`)
						end,
					},
					{
						Name = "Reduce empty table",
						Function = function()
							local tbl = {}
							local result = ExtendedTableLibrary.reduceTable(tbl, function(acc, key, value)
								return acc + value
							end, 42)
							assert(result == 42, `Empty table reduction failed: expected 42, got {result}`)
						end,
					},
					{
						Name = "Build new table structure",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3 }
							local result = ExtendedTableLibrary.reduceTable(tbl, function(acc, key, value)
								acc[value] = key
								return acc
							end, {})
							local expected = { [1] = "a", [2] = "b", [3] = "c" }
							assert(deepEqual(result, expected), "Build new table structure reduction failed")
						end,
					},
				},
			},

			-- groupTableBy tests
			{
				Name = "groupTableBy",
				TestCases = {
					{
						Name = "Group by value type",
						Function = function()
							local tbl = { a = 1, b = "hello", c = 2, d = "world", e = 3 }
							local result: any = ExtendedTableLibrary.groupTableBy(tbl, function(key, value)
								return type(value)
							end)

							assert(#result.number == 3, "Should have 3 numbers")
							assert(#result.string == 2, "Should have 2 strings")

							-- Check that all numbers are grouped correctly
							local numberSet = {}
							for _, v in result.number do
								numberSet[v] = true
							end
							assert(numberSet[1] and numberSet[2] and numberSet[3], "All numbers should be grouped")

							-- Check that all strings are grouped correctly
							local stringSet = {}
							for _, v in result.string do
								stringSet[v] = true
							end
							assert(stringSet["hello"] and stringSet["world"], "All strings should be grouped")
						end,
					},
					{
						Name = "Group by value range",
						Function = function()
							local tbl = { a = 1, b = 15, c = 25, d = 35, e = 45 }
							local result = ExtendedTableLibrary.groupTableBy(tbl, function(key, value)
								if value < 10 then
									return "small"
								elseif value < 30 then
									return "medium"
								else
									return "large"
								end
							end)

							assert(#result.small == 1, "Should have 1 small value")
							assert(#result.medium == 2, "Should have 2 medium values")
							assert(#result.large == 2, "Should have 2 large values")
							assert(result.small[1] == 1, "Small group should contain 1")
						end,
					},
					{
						Name = "Group by key pattern",
						Function = function()
							local tbl = { user1 = "Alice", admin1 = "Bob", user2 = "Charlie", admin2 = "David" }
							local result = ExtendedTableLibrary.groupTableBy(tbl, function(key, value)
								return string.sub(key, 1, 4) == "user" and "users" or "admins"
							end)

							assert(#result.users == 2, "Should have 2 users")
							assert(#result.admins == 2, "Should have 2 admins")
						end,
					},
					{
						Name = "Group empty table",
						Function = function()
							local tbl = {}
							local result = ExtendedTableLibrary.groupTableBy(tbl, function(key, value)
								return "group"
							end)

							assert(deepEqual(result, {}), "Empty table should return empty result")
						end,
					},
				},
			},

			-- tableToPairs tests
			{
				Name = "tableToPairs",
				TestCases = {
					{
						Name = "Convert simple table to pairs",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3 }
							local result: any = ExtendedTableLibrary.tableToPairs(tbl)

							assert(#result == 3, "Should have 3 pairs")

							-- Convert to a set for easier checking since order might vary
							local pairSet = {}
							for _, pair in result do
								pairSet[pair[1] .. ":" .. pair[2]] = true
							end

							assert(pairSet["a:1"] and pairSet["b:2"] and pairSet["c:3"], "All pairs should be present")
						end,
					},
					{
						Name = "Convert array to pairs",
						Function = function()
							local tbl = { "first", "second", "third" }
							local result: any = ExtendedTableLibrary.tableToPairs(tbl)

							assert(#result == 3, "Should have 3 pairs")

							-- Check specific pairs for arrays
							local foundPairs = {}
							for _, pair in result do
								foundPairs[pair[1]] = pair[2]
							end

							assert(foundPairs[1] == "first", "First pair should be {1, 'first'}")
							assert(foundPairs[2] == "second", "Second pair should be {2, 'second'}")
							assert(foundPairs[3] == "third", "Third pair should be {3, 'third'}")
						end,
					},
					{
						Name = "Convert empty table to pairs",
						Function = function()
							local tbl = {}
							local result = ExtendedTableLibrary.tableToPairs(tbl)

							assert(deepEqual(result, {}), "Empty table should return empty array")
						end,
					},
					{
						Name = "Convert mixed table to pairs",
						Function = function()
							local tbl = { a = "value", [1] = "first", [true] = "boolean" }
							local result = ExtendedTableLibrary.tableToPairs(tbl)

							assert(#result == 3, "Should have 3 pairs")
							-- All pairs should be arrays of length 2
							for _, pair in result do
								assert(#pair == 2, "Each pair should have exactly 2 elements")
							end
						end,
					},
				},
			},

			-- invertTable tests
			{
				Name = "invertTable",
				TestCases = {
					{
						Name = "Invert simple table",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3 }
							local result = ExtendedTableLibrary.invertTable(tbl)
							local expected = { [1] = "a", [2] = "b", [3] = "c" }

							assert(deepEqual(result, expected), "Simple table inversion failed")
						end,
					},
					{
						Name = "Invert with duplicate values",
						Function = function()
							local tbl = { a = 1, b = 1, c = 2 }
							local result = ExtendedTableLibrary.invertTable(tbl)

							-- Only one key should map to value 1, and one to value 2
							assert(result[1] ~= nil, "Should have a key for value 1")
							assert(result[2] ~= nil, "Should have a key for value 2")
							assert(result[1] == "a" or result[1] == "b", "Key for value 1 should be 'a' or 'b'")
							assert(result[2] == "c", "Key for value 2 should be 'c'")
						end,
					},
					{
						Name = "Invert empty table",
						Function = function()
							local tbl = {}
							local result = ExtendedTableLibrary.invertTable(tbl)

							assert(deepEqual(result, {}), "Empty table inversion should return empty table")
						end,
					},
					{
						Name = "Invert with mixed value types",
						Function = function()
							local tbl = { a = "hello", b = 42, c = true }
							local result = ExtendedTableLibrary.invertTable(tbl)
							local expected = { hello = "a", [42] = "b", [true] = "c" }

							assert(deepEqual(result, expected), "Mixed type inversion failed")
						end,
					},
				},
			},

			-- tableIntersection tests
			{
				Name = "tableIntersection",
				TestCases = {
					{
						Name = "Basic intersection (keys only)",
						Function = function()
							local tbl1 = { a = 1, b = 2, c = 3 }
							local tbl2 = { a = 10, b = 20, d = 5 }
							local result = ExtendedTableLibrary.tableIntersection(tbl1, tbl2)
							local expected = { a = 1, b = 2 }

							assert(deepEqual(result, expected), "Basic intersection (keys only) failed")
						end,
					},
					{
						Name = "Basic intersection (keys and values)",
						Function = function()
							local tbl1 = { a = 1, b = 2, c = 3 }
							local tbl2 = { a = 1, b = 4, d = 5 }
							local result = ExtendedTableLibrary.tableIntersection(tbl1, tbl2, true)
							local expected = { a = 1 }

							assert(deepEqual(result, expected), "Basic intersection (keys and values) failed")
						end,
					},
					{
						Name = "No intersection (keys only)",
						Function = function()
							local tbl1 = { a = 1, b = 2 }
							local tbl2 = { c = 3, d = 4 }
							local result = ExtendedTableLibrary.tableIntersection(tbl1, tbl2)

							assert(deepEqual(result, {}), "No intersection should return empty table")
						end,
					},
					{
						Name = "No intersection (keys and values)",
						Function = function()
							local tbl1 = { a = 1, b = 2 }
							local tbl2 = { a = 10, b = 20 }
							local result = ExtendedTableLibrary.tableIntersection(tbl1, tbl2, true)

							assert(deepEqual(result, {}), "No intersection with value matching should return empty table")
						end,
					},
					{
						Name = "Full intersection (keys only)",
						Function = function()
							local tbl1 = { a = 1, b = 2, c = 3 }
							local tbl2 = { a = 10, b = 20, c = 30 }
							local result = ExtendedTableLibrary.tableIntersection(tbl1, tbl2)

							assert(deepEqual(result, tbl1), "Full intersection (keys only) should return first table")
						end,
					},
					{
						Name = "Full intersection (keys and values)",
						Function = function()
							local tbl1 = { a = 1, b = 2, c = 3 }
							local tbl2 = { a = 1, b = 2, c = 3 }
							local result = ExtendedTableLibrary.tableIntersection(tbl1, tbl2, true)

							assert(deepEqual(result, tbl1), "Full intersection (keys and values) should return identical table")
						end,
					},
					{
						Name = "Intersection with empty table",
						Function = function()
							local tbl1 = { a = 1, b = 2 }
							local tbl2 = {}
							local result = ExtendedTableLibrary.tableIntersection(tbl1, tbl2)

							assert(deepEqual(result, {}), "Intersection with empty table should be empty")
						end,
					},
					{
						Name = "Partial value match",
						Function = function()
							local tbl1 = { a = 1, b = 2, c = 3, d = 4 }
							local tbl2 = { a = 1, b = 20, c = 3, e = 4 }
							local result = ExtendedTableLibrary.tableIntersection(tbl1, tbl2, true)
							local expected = { a = 1, c = 3 }

							assert(deepEqual(result, expected), "Partial value match intersection failed")
						end,
					},
				},
			},

			-- tableDifference tests
			{
				Name = "tableDifference",
				TestCases = {
					{
						Name = "Basic difference (keys only)",
						Function = function()
							local tbl1 = { a = 1, b = 2, c = 3 }
							local tbl2 = { a = 10, d = 4 }
							local result = ExtendedTableLibrary.tableDifference(tbl1, tbl2)
							local expected = { b = 2, c = 3 }

							assert(deepEqual(result, expected), "Basic difference (keys only) failed")
						end,
					},
					{
						Name = "No difference",
						Function = function()
							local tbl1 = { a = 1, b = 2 }
							local tbl2 = { a = 1, b = 2, c = 3 }
							local result = ExtendedTableLibrary.tableDifference(tbl1, tbl2)

							assert(deepEqual(result, {}), "No difference should return empty table")
						end,
					},
					{
						Name = "Complete difference",
						Function = function()
							local tbl1 = { a = 1, b = 2 }
							local tbl2 = { c = 3, d = 4 }
							local result = ExtendedTableLibrary.tableDifference(tbl1, tbl2)

							assert(deepEqual(result, tbl1), "Complete difference should return first table")
						end,
					},
					{
						Name = "Difference with empty second table",
						Function = function()
							local tbl1 = { a = 1, b = 2 }
							local tbl2 = {}
							local result = ExtendedTableLibrary.tableDifference(tbl1, tbl2)

							assert(deepEqual(result, tbl1), "Difference with empty second table should return first table")
						end,
					},
					{
						Name = "Value matching difference",
						Function = function()
							local tbl1 = { a = 1, b = 2, c = 3 }
							local tbl2 = { a = 1, b = 5, d = 2 }
							local result = ExtendedTableLibrary.tableDifference(tbl1, tbl2, true, false)
							local expected = { b = 2 }

							assert(deepEqual(result, expected), "Value matching difference failed")
						end,
					},
					{
						Name = "Value matching with no differences",
						Function = function()
							local tbl1 = { a = 1, b = 2, c = 3 }
							local tbl2 = { a = 1, b = 2, d = 4 }
							local result = ExtendedTableLibrary.tableDifference(tbl1, tbl2, true, false)
							local expected = {}

							assert(deepEqual(result, expected), "Value matching with no differences should return empty table")
						end,
					},
					{
						Name = "Symmetric difference",
						Function = function()
							local tbl1 = { a = 1, b = 2, c = 3 }
							local tbl2 = { a = 1, d = 4, e = 5 }
							local result = ExtendedTableLibrary.tableDifference(tbl1, tbl2, false, true)
							local expected = { b = 2, c = 3, d = 4, e = 5 }

							assert(deepEqual(result, expected), "Symmetric difference failed")
						end,
					},
					{
						Name = "Symmetric difference with no overlap",
						Function = function()
							local tbl1 = { a = 1, b = 2 }
							local tbl2 = { c = 3, d = 4 }
							local result = ExtendedTableLibrary.tableDifference(tbl1, tbl2, false, true)
							local expected = { a = 1, b = 2, c = 3, d = 4 }

							assert(deepEqual(result, expected), "Symmetric difference with no overlap failed")
						end,
					},
					{
						Name = "Symmetric difference with complete overlap",
						Function = function()
							local tbl1 = { a = 1, b = 2 }
							local tbl2 = { a = 1, b = 2 }
							local result = ExtendedTableLibrary.tableDifference(tbl1, tbl2, false, true)
							local expected = {}

							assert(deepEqual(result, expected), "Symmetric difference with complete overlap should return empty table")
						end,
					},
					{
						Name = "Incompatible options error",
						Function = function()
							local tbl1 = { a = 1, b = 2 }
							local tbl2 = { a = 1, c = 3 }
							local success = pcall(ExtendedTableLibrary.tableDifference, tbl1, tbl2, true, true)

							assert(not success, "Should throw error when both matchValue and symmetric are true")
						end,
					},
				},
			},

			-- removeAll tests
			{
				Name = "removeAll",
				TestCases = {
					{
						Name = "Remove single value",
						Function = function()
							local tbl = { a = 1, b = 2, c = 1, d = 3 }
							ExtendedTableLibrary.removeAll(tbl, 1)
							local expected = { b = 2, d = 3 }

							assert(deepEqual(tbl, expected), "Remove single value failed")
						end,
					},
					{
						Name = "Remove multiple values",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3, d = 2, e = 4 }
							ExtendedTableLibrary.removeAll(tbl, { 1, 3 })
							local expected = { b = 2, d = 2, e = 4 }

							assert(deepEqual(tbl, expected), "Remove multiple values failed")
						end,
					},
					{
						Name = "Remove non-existent value",
						Function = function()
							local tbl = { a = 1, b = 2, c = 3 }
							local original = { a = 1, b = 2, c = 3 }
							ExtendedTableLibrary.removeAll(tbl, 5)

							assert(deepEqual(tbl, original), "Table should remain unchanged when removing non-existent value")
						end,
					},
					{
						Name = "Remove from empty table",
						Function = function()
							local tbl = {}
							ExtendedTableLibrary.removeAll(tbl, 1)

							assert(deepEqual(tbl, {}), "Empty table should remain empty")
						end,
					},
					{
						Name = "Remove all occurrences",
						Function = function()
							local tbl = { a = "test", b = "test", c = "other", d = "test" }
							ExtendedTableLibrary.removeAll(tbl, "test")
							local expected = { c = "other" }

							assert(deepEqual(tbl, expected), "Should remove all occurrences of the value")
						end,
					},
				},
			},
		},
	},

	[3] = {
		Name = "Array Manipulation",

		TestCases = {
			{
				Name = "extendArraySize",
				Function = function()
					for i = 0, 2 ^ 13 do
						local testArray = table.create(i)
						ExtendedTableLibrary.extendArraySize(testArray, i)

						local expectedSize = i * 2
						local actualSize = ExtendedTableLibrary.getAllocatedArraySize(testArray)
						assert(actualSize == expectedSize, `Failed for index {i}: Array size should be {expectedSize}, got {actualSize}`)
					end
				end,
			},

			{
				Name = "setArraySize",

				TestCases = {
					{
						Name = "setArraySize 0 -> 1024",

						Function = function()
							local testArray = table.create(0)
							local newSize = 2 ^ 10
							ExtendedTableLibrary.setArraySize(testArray, newSize)

							local actualSize = ExtendedTableLibrary.getAllocatedArraySize(testArray)
							assert(actualSize == newSize, `Array size should be {newSize}, got {ExtendedTableLibrary.getAllocatedArraySize(testArray)}`)
						end,
					},
					{
						Name = "setArraySize 1024 -> 2048",

						Function = function()
							local testArray = table.create(2 ^ 10)
							local newSize = 2 ^ 11
							ExtendedTableLibrary.setArraySize(testArray, newSize)

							local actualSize = ExtendedTableLibrary.getAllocatedArraySize(testArray)
							assert(actualSize == newSize, `Array size should be {newSize}, got {ExtendedTableLibrary.getAllocatedArraySize(testArray)}`)
						end,
					}
				}
			},

			{
				Name = "truncateArray",
				TestCases = {
					{
						Name = "Truncate larger array to smaller size",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.truncateArray(array, 3)
							local expected = {1, 2, 3}
							assert(deepEqual(result, expected), "Truncate to smaller size failed")
						end,
					},
					{
						Name = "Truncate to size 0",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.truncateArray(array, 0)
							local expected = {}
							assert(deepEqual(result, expected), "Truncate to size 0 failed")
						end,
					},
					{
						Name = "Truncate to same size",
						Function = function()
							local array = {1, 2, 3}
							local result = ExtendedTableLibrary.truncateArray(array, 3)
							local expected = {1, 2, 3}
							assert(deepEqual(result, expected), "Truncate to same size failed")
						end,
					},
					{
						Name = "Truncate to larger size (no change)",
						Function = function()
							local array = {1, 2, 3}
							local result = ExtendedTableLibrary.truncateArray(array, 5)
							local expected = {1, 2, 3}
							assert(deepEqual(result, expected), "Truncate to larger size should not change array")
						end,
					},
					{
						Name = "Truncate empty array",
						Function = function()
							local array = {}
							local result = ExtendedTableLibrary.truncateArray(array, 3)
							local expected = {}
							assert(deepEqual(result, expected), "Truncate empty array failed")
						end,
					},
					{
						Name = "Truncate single element array",
						Function = function()
							local array = {"only"}
							local result = ExtendedTableLibrary.truncateArray(array, 0)
							local expected = {}
							assert(deepEqual(result, expected), "Truncate single element array to 0 failed")
						end,
					},
				},
			},

			-- concatArrays tests
			{
				Name = "concatArrays",
				TestCases = {
					{
						Name = "Concatenate multiple arrays",
						Function = function()
							local arr1 = {1, 2, 3}
							local arr2 = {4, 5}
							local arr3 = {6, 7, 8, 9}
							local result = ExtendedTableLibrary.concatArrays(false, arr1, arr2, arr3)
							local expected = {1, 2, 3, 4, 5, 6, 7, 8, 9}
							assert(deepEqual(result, expected), "Concatenate multiple arrays failed")
						end,
					},
					{
						Name = "Concatenate in place",
						Function = function()
							local arr1 = {1, 2, 3}
							local arr2 = {4, 5}
							local arr3 = {6, 7}
							local result = ExtendedTableLibrary.concatArrays(true, arr1, arr2, arr3)
							assert(result == arr1, "In-place concatenation should return first array")
							assert(deepEqual(arr1, {1, 2, 3, 4, 5, 6, 7}), "In-place concatenation failed")
						end,
					},
					{
						Name = "Concatenate with empty arrays",
						Function = function()
							local arr1 = {1, 2}
							local arr2 = {}
							local arr3 = {3, 4}
							local result = ExtendedTableLibrary.concatArrays(false, arr1, arr2, arr3)
							local expected = {1, 2, 3, 4}
							assert(deepEqual(result, expected), "Concatenate with empty arrays failed")
						end,
					},
					{
						Name = "Concatenate single array",
						Function = function()
							local arr1 = {1, 2, 3}
							local result = ExtendedTableLibrary.concatArrays(false, arr1)
							local expected = {1, 2, 3}
							assert(deepEqual(result, expected), "Concatenate single array failed")
							assert(result ~= arr1, "Should return new array when not in-place")
						end,
					},
					{
						Name = "Concatenate all empty arrays",
						Function = function()
							local arr1 = {}
							local arr2 = {}
							local result = ExtendedTableLibrary.concatArrays(false, arr1, arr2)
							local expected = {}
							assert(deepEqual(result, expected), "Concatenate all empty arrays failed")
						end,
					},
				},
			},

			-- unionArrays tests
			{
				Name = "unionArrays",
				TestCases = {
					{
						Name = "Union with duplicates",
						Function = function()
							local arr1 = {1, 2, 3}
							local arr2 = {2, 3, 4}
							local arr3 = {3, 4, 5}
							local result = ExtendedTableLibrary.unionArrays(arr1, arr2, arr3)

							-- Check that all unique elements are still present
							local resultSet = {}
							for _, v in result do
								resultSet[v] = true
							end

							assert(resultSet[1] and resultSet[2] and resultSet[3] and resultSet[4] and resultSet[5], "All unique elements should be present")
							assert(#result == 5, "Should have 5 unique elements")
						end,
					},
					{
						Name = "Union with no duplicates",
						Function = function()
							local arr1 = {1, 2}
							local arr2 = {3, 4}
							local arr3 = {5, 6}
							local result = ExtendedTableLibrary.unionArrays(arr1, arr2, arr3)
							local expected = {1, 2, 3, 4, 5, 6}

							-- Check length and all elements present
							assert(#result == 6, "Should have 6 elements")
							local resultSet = {}
							for _, v in result do
								resultSet[v] = true
							end
							for _, v in expected do
								assert(resultSet[v], `Element {v} should be present`)
							end
						end,
					},
					{
						Name = "Union with empty arrays",
						Function = function()
							local arr1 = {1, 2}
							local arr2 = {}
							local arr3 = {3, 4}
							local result = ExtendedTableLibrary.unionArrays(arr1, arr2, arr3)

							assert(#result == 4, "Should have 4 elements")
							local resultSet = {}
							for _, v in result do
								resultSet[v] = true
							end
							assert(resultSet[1] and resultSet[2] and resultSet[3] and resultSet[4], "All elements should be present")
						end,
					},
					{
						Name = "Union single array",
						Function = function()
							local arr1 = {1, 2, 2, 3, 3, 3}
							local result = ExtendedTableLibrary.unionArrays(arr1)

							assert(#result == 3, "Should have 3 unique elements")
							local resultSet = {}
							for _, v in result do
								resultSet[v] = true
							end
							assert(resultSet[1] and resultSet[2] and resultSet[3], "All unique elements should be present")
						end,
					},
					{
						Name = "Union all empty arrays",
						Function = function()
							local arr1 = {}
							local arr2 = {}
							local result = ExtendedTableLibrary.unionArrays(arr1, arr2)
							local expected = {}
							assert(deepEqual(result, expected), "Union of empty arrays should be empty")
						end,
					},
				},
			},

			-- flattenArray tests
			{
				Name = "flattenArray",
				TestCases = {
					{
						Name = "Flatten nested arrays fully",
						Function = function()
							local nestedArray = {{1, 2}, {3, {4, 5}}, {6}}
							local result = ExtendedTableLibrary.flattenArray(nestedArray)
							print(result)
							local expected = {1, 2, 3, 4, 5, 6}
							assert(deepEqual(result, expected), "Full flatten failed")
						end,
					},
					{
						Name = "Flatten with depth limit",
						Function = function()
							local nestedArray = {{1, 2}, {3, {4, 5}}, {6}}
							local result = ExtendedTableLibrary.flattenArray(nestedArray, 1)
							local expected = {1, 2, 3, {4, 5}, 6}
							assert(deepEqual(result, expected), "Depth-limited flatten failed")
						end,
					},
					{
						Name = "Flatten already flat array",
						Function = function()
							local flatArray = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.flattenArray(flatArray)
							local expected = {1, 2, 3, 4, 5}
							assert(deepEqual(result, expected), "Flatten flat array failed")
						end,
					},
					{
						Name = "Flatten deeply nested array",
						Function = function()
							local deepArray = {{{1, 2}}, {{3, {4, 5}}}}
							local result = ExtendedTableLibrary.flattenArray(deepArray)
							local expected = {1, 2, 3, 4, 5}
							assert(deepEqual(result, expected), "Deep flatten failed")
						end,
					},
					{
						Name = "Flatten with depth 0 (no change)",
						Function = function()
							local nestedArray = {{1, 2}, {3, 4}}
							local result = ExtendedTableLibrary.flattenArray(nestedArray, 0)
							local expected = {{1, 2}, {3, 4}}
							assert(deepEqual(result, expected), "Flatten with depth 0 should not change array")
						end,
					},
					{
						Name = "Flatten empty array",
						Function = function()
							local emptyArray = {}
							local result = ExtendedTableLibrary.flattenArray(emptyArray)
							local expected = {}
							assert(deepEqual(result, expected), "Flatten empty array failed")
						end,
					},
					{
						Name = "Flatten array with empty subarrays",
						Function = function()
							local arrayWithEmpties = {{1, 2}, {}, {3, 4}}
							local result = ExtendedTableLibrary.flattenArray(arrayWithEmpties)
							local expected = {1, 2, 3, 4}
							assert(deepEqual(result, expected), "Flatten with empty subarrays failed")
						end,
					},
				},
			},

			-- compactArray tests
			{
				Name = "compactArray",
				TestCases = {
					{
						Name = "Compact sparse array (hash portion)",
						Function = function()
							local sparseArray = {[1] = "a", [3] = "c", [5] = "e", [7] = "g"}
							local result = ExtendedTableLibrary.compactArray(sparseArray)
							local expected = {"a", "c", "e", "g"}
							assert(deepEqual(result, expected), "Compact sparse array failed")
						end,
					},
					{
						Name = "Compact sparse array with isArray=true",
						Function = function()
							local sparseArray = table.create(7)
							sparseArray[1] = "a"
							sparseArray[3] = "c"
							sparseArray[5] = "e"
							sparseArray[7] = "g"
							local result = ExtendedTableLibrary.compactArray(sparseArray, false, true)
							local expected = {"a", "c", "e", "g"}
							assert(deepEqual(result, expected), "Compact sparse array with isArray=true failed")
						end,
					},
					{
						Name = "Compact already contiguous array",
						Function = function()
							local contiguousArray = {"a", "b", "c", "d"}
							local result = ExtendedTableLibrary.compactArray(contiguousArray)
							local expected = {"a", "b", "c", "d"}
							assert(deepEqual(result, expected), "Compact contiguous array failed")
						end,
					},
					{
						Name = "Compact contiguous array with isArray=true",
						Function = function()
							local contiguousArray = table.create(4)
							contiguousArray[1] = "a"
							contiguousArray[2] = "b"
							contiguousArray[3] = "c"
							contiguousArray[4] = "d"
							local result = ExtendedTableLibrary.compactArray(contiguousArray, false, true)
							-- Should return the same array since it's already compact
							assert(result == contiguousArray, "Compact contiguous array with isArray=true should return same array")
						end,
					},
					{
						Name = "Compact with allocateExactSize true",
						Function = function()
							local sparseArray = {[1] = "a", [3] = "c", [5] = "e"}
							local result = ExtendedTableLibrary.compactArray(sparseArray, true)
							local expected = {"a", "c", "e"}
							assert(deepEqual(result, expected), "Compact with exact size allocation failed")
							assert(ExtendedTableLibrary.getAllocatedArraySize(result) == 3, "Result should have exact size allocation")
						end,
					},
					{
						Name = "Compact with allocateExactSize true and isArray=true",
						Function = function()
							local sparseArray = table.create(5)
							sparseArray[1] = "a"
							sparseArray[3] = "c"
							sparseArray[5] = "e"
							local result = ExtendedTableLibrary.compactArray(sparseArray, true, true)
							local expected = {"a", "c", "e"}
							assert(deepEqual(result, expected), "Compact with exact size allocation and isArray=true failed")
							assert(ExtendedTableLibrary.getAllocatedArraySize(result) == 3, "Result should have exact size allocation")
						end,
					},
					{
						Name = "Compact empty array",
						Function = function()
							local emptyArray = {}
							local result = ExtendedTableLibrary.compactArray(emptyArray)
							local expected = {}
							assert(deepEqual(result, expected), "Compact empty array failed")
						end,
					},
					{
						Name = "Compact empty array with isArray=true",
						Function = function()
							local emptyArray = table.create(0)
							local result = ExtendedTableLibrary.compactArray(emptyArray, false, true)
							local expected = {}
							assert(deepEqual(result, expected), "Compact empty array with isArray=true failed")
						end,
					},
					{
						Name = "Compact array with gaps at beginning",
						Function = function()
							local arrayWithGaps = {[3] = "c", [4] = "d", [5] = "e"}
							local result = ExtendedTableLibrary.compactArray(arrayWithGaps)
							local expected = {"c", "d", "e"}
							assert(deepEqual(result, expected), "Compact array with gaps at beginning failed")
						end,
					},
					{
						Name = "Compact array with gaps at beginning (isArray=true)",
						Function = function()
							local arrayWithGaps = table.create(5)
							arrayWithGaps[3] = "c"
							arrayWithGaps[4] = "d"
							arrayWithGaps[5] = "e"
							local result = ExtendedTableLibrary.compactArray(arrayWithGaps, false, true)
							local expected = {"c", "d", "e"}
							assert(deepEqual(result, expected), "Compact array with gaps at beginning (isArray=true) failed")
						end,
					},
					{
						Name = "Compact array with gaps in middle",
						Function = function()
							local arrayWithGaps = {[1] = "a", [3] = "c", [4] = "d", [6] = "f"}
							local result = ExtendedTableLibrary.compactArray(arrayWithGaps)
							local expected = {"a", "c", "d", "f"}
							assert(deepEqual(result, expected), "Compact array with gaps in middle failed")
						end,
					},
					{
						Name = "Compact array with gaps in middle (isArray=true)",
						Function = function()
							local arrayWithGaps = table.create(6)
							arrayWithGaps[1] = "a"
							arrayWithGaps[3] = "c"
							arrayWithGaps[4] = "d"
							arrayWithGaps[6] = "f"
							local result = ExtendedTableLibrary.compactArray(arrayWithGaps, false, true)
							local expected = {"a", "c", "d", "f"}
							assert(deepEqual(result, expected), "Compact array with gaps in middle (isArray=true) failed")
						end,
					},
					{
						Name = "Compact single element sparse array",
						Function = function()
							local singleElement = {[5] = "only"}
							local result = ExtendedTableLibrary.compactArray(singleElement)
							local expected = {"only"}
							assert(deepEqual(result, expected), "Compact single element sparse array failed")
						end,
					},
					{
						Name = "Compact single element sparse array (isArray=true)",
						Function = function()
							local singleElement = table.create(5)
							singleElement[5] = "only"
							local result = ExtendedTableLibrary.compactArray(singleElement, false, true)
							local expected = {"only"}
							assert(deepEqual(result, expected), "Compact single element sparse array (isArray=true) failed")
						end,
					},
					{
						Name = "compactArray Comprehensive State Tests",
						TestCases = {
							{
								Name = "compactArray with all possible nil patterns for size 8 arrays",
								Function = function()
									-- Helper function to create array with nil at specified positions
									local function createArrayWithNils(nilPositions)
										local array = {}
										for i = 1, 8 do
											local isNil = false
											for _, pos in nilPositions do
												if i == pos then
													isNil = true
													break
												end
											end
											if not isNil then
												array[i] = `value{i}`
											end
										end
										return array
									end

									-- Helper function to get expected compact result
									local function getExpectedCompact(nilPositions)
										local expected = {}
										for i = 1, 8 do
											local isNil = false
											for _, pos in nilPositions do
												if i == pos then
													isNil = true
													break
												end
											end
											if not isNil then
												table.insert(expected, `value{i}`)
											end
										end
										return expected
									end

									-- Test with 0 nils (contiguous array)
									local array0 = {`value1`, `value2`, `value3`, `value4`, `value5`, `value6`, `value7`, `value8`}
									local result0 = ExtendedTableLibrary.compactArray(array0)
									local expected0 = {`value1`, `value2`, `value3`, `value4`, `value5`, `value6`, `value7`, `value8`}
									assert(deepEqual(result0, expected0), "compactArray failed for 0 nils")

									-- Test with 1 nil at each position
									for nilPos = 1, 8 do
										local array = createArrayWithNils({nilPos})
										local result = ExtendedTableLibrary.compactArray(array)
										local expected = getExpectedCompact({nilPos})
										assert(deepEqual(result, expected), `compactArray failed for 1 nil at position {nilPos}`)
									end

									-- Test with 2 nils at various positions
									for pos1 = 1, 7 do
										for pos2 = pos1 + 1, 8 do
											local array = createArrayWithNils({pos1, pos2})
											local result = ExtendedTableLibrary.compactArray(array)
											local expected = getExpectedCompact({pos1, pos2})
											assert(deepEqual(result, expected), `compactArray failed for 2 nils at positions {pos1}, {pos2}`)
										end
									end

									-- Test with 3 nils at various positions (sampling key cases)
									local testCases3 = {
										{1, 2, 3}, -- beginning
										{6, 7, 8}, -- end
										{3, 4, 5}, -- middle
										{1, 4, 8}, -- scattered
										{2, 5, 7}, -- scattered
									}
									for _, nilPositions in testCases3 do
										local array = createArrayWithNils(nilPositions)
										local result = ExtendedTableLibrary.compactArray(array)
										local expected = getExpectedCompact(nilPositions)
										assert(deepEqual(result, expected), `compactArray failed for 3 nils at positions {table.concat(nilPositions, ", ")}`)
									end

									-- Test with 4 nils at various positions (sampling key cases)
									local testCases4 = {
										{1, 2, 3, 4}, -- beginning
										{5, 6, 7, 8}, -- end
										{2, 4, 6, 8}, -- even positions
										{1, 3, 5, 7}, -- odd positions
										{1, 3, 6, 8}, -- scattered
									}
									for _, nilPositions in testCases4 do
										local array = createArrayWithNils(nilPositions)
										local result = ExtendedTableLibrary.compactArray(array)
										local expected = getExpectedCompact(nilPositions)
										assert(deepEqual(result, expected), `compactArray failed for 4 nils at positions {table.concat(nilPositions, ", ")}`)
									end

									-- Test with 5 nils (sampling key cases)
									local testCases5 = {
										{1, 2, 3, 4, 5}, -- beginning
										{4, 5, 6, 7, 8}, -- end
										{1, 3, 5, 6, 8}, -- scattered
										{2, 3, 4, 7, 8}, -- mixed
									}
									for _, nilPositions in testCases5 do
										local array = createArrayWithNils(nilPositions)
										local result = ExtendedTableLibrary.compactArray(array)
										local expected = getExpectedCompact(nilPositions)
										assert(deepEqual(result, expected), `compactArray failed for 5 nils at positions {table.concat(nilPositions, ", ")}`)
									end

									-- Test with 6 nils (sampling key cases)
									local testCases6 = {
										{1, 2, 3, 4, 5, 6}, -- beginning
										{3, 4, 5, 6, 7, 8}, -- end
										{1, 2, 4, 6, 7, 8}, -- scattered
									}
									for _, nilPositions in testCases6 do
										local array = createArrayWithNils(nilPositions)
										local result = ExtendedTableLibrary.compactArray(array)
										local expected = getExpectedCompact(nilPositions)
										assert(deepEqual(result, expected), `compactArray failed for 6 nils at positions {table.concat(nilPositions, ", ")}`)
									end

									-- Test with 7 nils (each position can be the non-nil one)
									for nonNilPos = 1, 8 do
										local nilPositions = {}
										for i = 1, 8 do
											if i ~= nonNilPos then
												table.insert(nilPositions, i)
											end
										end
										local array = createArrayWithNils(nilPositions)
										local result = ExtendedTableLibrary.compactArray(array)
										local expected = {`value{nonNilPos}`}
										assert(deepEqual(result, expected), `compactArray failed for 7 nils, non-nil at position {nonNilPos}`)
									end

									-- Test with 8 nils (all nil)
									local array8 = {}
									for i = 1, 8 do
										array8[i] = nil
									end
									local result8 = ExtendedTableLibrary.compactArray(array8)
									local expected8 = {}
									assert(deepEqual(result8, expected8), "compactArray failed for 8 nils (all nil)")

									print("All compactArray state tests passed!")
								end,
							},

							{
								Name = "compactArray with sparse arrays (hash portion)",
								Function = function()
									-- Test sparse arrays where elements are in hash portion
									local testCases = {
										-- Various sparse patterns
										{indices = {1, 3, 5, 7}, values = {"a", "c", "e", "g"}},
										{indices = {2, 4, 6, 8}, values = {"b", "d", "f", "h"}},
										{indices = {1, 2, 7, 8}, values = {"a", "b", "g", "h"}},
										{indices = {3, 4, 5, 6}, values = {"c", "d", "e", "f"}},
										{indices = {1, 8}, values = {"a", "h"}},
										{indices = {4, 5}, values = {"d", "e"}},
										{indices = {2, 3, 4, 5, 6, 7}, values = {"b", "c", "d", "e", "f", "g"}},
										{indices = {1}, values = {"a"}},
										{indices = {8}, values = {"h"}},
									}

									for _, testCase in testCases do
										local sparseArray = {}
										for i, index in testCase.indices do
											sparseArray[index] = testCase.values[i]
										end

										local result = ExtendedTableLibrary.compactArray(sparseArray)
										assert(deepEqual(result, testCase.values), `compactArray failed for sparse array with indices {table.concat(testCase.indices, ", ")}`)
									end
								end,
							},

							{
								Name = "compactArray with isArray=true flag",
								Function = function()
									-- Test with isArray=true for various patterns
									local testCases = {
										{size = 8, nils = {}, expected = {"a", "b", "c", "d", "e", "f", "g", "h"}},
										{size = 8, nils = {3, 6}, expected = {"a", "b", "d", "e", "g", "h"}},
										{size = 8, nils = {1, 8}, expected = {"b", "c", "d", "e", "f", "g"}},
										{size = 8, nils = {2, 4, 6, 8}, expected = {"a", "c", "e", "g"}},
										{size = 8, nils = {1, 2, 3, 4}, expected = {"e", "f", "g", "h"}},
										{size = 8, nils = {5, 6, 7, 8}, expected = {"a", "b", "c", "d"}},
									}

									for _, testCase in testCases do
										local array = table.create(testCase.size)
										local valueIndex = 1
										for i = 1, testCase.size do
											if table.find(testCase.nils, i) then continue end
											array[i] = string.char(96 + i) -- a, b, c, etc.
											valueIndex += 1
										end

										assert(ExtendedTableLibrary.getAllocatedArraySize(array) == testCase.size, `Array should be allocated with size {testCase.size}`)
										local result = ExtendedTableLibrary.compactArray(array, false, true)
										assert(deepEqual(result, testCase.expected), `compactArray with isArray=true failed for nils at {table.concat(testCase.nils, ", ")}`)
									end
								end,
							},

							{
								Name = "compactArray with allocateExactSize=true",
								Function = function()
									-- Test exact size allocation for various cases
									local testCases = {
										{input = {"a", nil, "c", nil, "e"}, expectedSize = 3},
										{input = {nil, "b", nil, "d", nil}, expectedSize = 2},
										{input = {"a", "b", "c", "d", "e", "f", "g", "h"}, expectedSize = 8},
										{input = {nil, nil, nil, nil, nil, nil, nil, "h"}, expectedSize = 1},
										{input = {}, expectedSize = 0},
									}

									for _, testCase in testCases do
										local result = ExtendedTableLibrary.compactArray(testCase.input, true)
										local actualSize = ExtendedTableLibrary.getAllocatedArraySize(result)
										assert(actualSize == testCase.expectedSize, `compactArray with allocateExactSize failed: expected size {testCase.expectedSize}, got {actualSize}`)
									end
								end,
							},

							{
								Name = "compactArray edge cases",
								Function = function()
									-- Test various edge cases

									-- Empty array
									local empty = {}
									local resultEmpty = ExtendedTableLibrary.compactArray(empty)
									assert(deepEqual(resultEmpty, {}), "compactArray failed for empty array")

									-- Single element at various positions
									for pos = 1, 8 do
										local singleArray = {}
										singleArray[pos] = `value{pos}`
										local result = ExtendedTableLibrary.compactArray(singleArray)
										assert(deepEqual(result, {`value{pos}`}), `compactArray failed for single element at position {pos}`)
									end

									-- All elements at beginning
									local beginArray = {"a", "b", "c"}
									local resultBegin = ExtendedTableLibrary.compactArray(beginArray)
									assert(deepEqual(resultBegin, {"a", "b", "c"}), "compactArray failed for elements at beginning")

									-- All elements at end
									local endArray = {}
									endArray[6] = "f"
									endArray[7] = "g"
									endArray[8] = "h"
									local resultEnd = ExtendedTableLibrary.compactArray(endArray)
									assert(deepEqual(resultEnd, {"f", "g", "h"}), "compactArray failed for elements at end")

									-- Alternating pattern
									local altArray = {}
									altArray[1] = "a"
									altArray[3] = "c"
									altArray[5] = "e"
									altArray[7] = "g"
									local resultAlt = ExtendedTableLibrary.compactArray(altArray)
									assert(deepEqual(resultAlt, {"a", "c", "e", "g"}), "compactArray failed for alternating pattern")
								end,
							},
						},
					},
				},
			},

			-- fillWithValue tests
			{
				Name = "fillWithValue",
				TestCases = {
					{
						Name = "Fill entire array with value",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.fillWithValue(array, 0)
							local expected = {0, 0, 0, 0, 0}
							assert(deepEqual(array, expected), "Fill entire array failed")
						end,
					},
					{
						Name = "Fill array with start and end index",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.fillWithValue(array, 9, 2, 4)
							local expected = {1, 9, 9, 9, 5}
							assert(deepEqual(array, expected), "Fill with start and end index failed")
						end,
					},
					{
						Name = "Fill array with start index only",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.fillWithValue(array, 7, 3)
							local expected = {1, 2, 7, 7, 7}
							assert(deepEqual(array, expected), "Fill with start index only failed")
						end,
					},
					{
						Name = "Fill array with source array optimization",
						Function = function()
							local array = {1, 2, 3, 4, 5, 6, 7, 8}
							local sourceArray = table.create(5, 9) -- Pre-allocated array with same value
							ExtendedTableLibrary.fillWithValue(array, 9, 2, 7, sourceArray)
							local expected = {1, 9, 9, 9, 9, 9, 9, 8}
							assert(deepEqual(array, expected), "Fill with source array optimization failed")
						end,
					},
					{
						Name = "Fill empty array",
						Function = function()
							local array = {}
							ExtendedTableLibrary.fillWithValue(array, 5)
							local expected = {}
							assert(deepEqual(array, expected), "Fill empty array should not change it")
						end,
					},
					{
						Name = "Fill single element array",
						Function = function()
							local array = {1}
							ExtendedTableLibrary.fillWithValue(array, 9)
							local expected = {9}
							assert(deepEqual(array, expected), "Fill single element array failed")
						end,
					},
					{
						Name = "Fill with string value",
						Function = function()
							local array = {"a", "b", "c", "d"}
							ExtendedTableLibrary.fillWithValue(array, "x", 2, 3)
							local expected = {"a", "x", "x", "d"}
							assert(deepEqual(array, expected), "Fill with string value failed")
						end,
					},
				},
			},

			-- fillWithPattern tests
			{
				Name = "fillWithPattern",
				TestCases = {
					{
						Name = "Fill array with repeating pattern",
						Function = function()
							local array = {1, 2, 3, 4, 5, 6, 7, 8}
							local pattern = {"a", "b", "c"}
							ExtendedTableLibrary.fillWithPattern(array, pattern, 2, 7)
							local expected = {1, "a", "b", "c", "a", "b", "c", 8}
							assert(deepEqual(array, expected), "Fill with repeating pattern failed")
						end,
					},
					{
						Name = "Fill entire array with pattern",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local pattern = {"x", "y"}
							ExtendedTableLibrary.fillWithPattern(array, pattern)
							local expected = {"x", "y", "x", "y", "x"}
							assert(deepEqual(array, expected), "Fill entire array with pattern failed")
						end,
					},
					{
						Name = "Fill with single element pattern",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local pattern = {9}
							ExtendedTableLibrary.fillWithPattern(array, pattern, 2, 4)
							local expected = {1, 9, 9, 9, 5}
							assert(deepEqual(array, expected), "Fill with single element pattern failed")
						end,
					},
					{
						Name = "Fill with pattern larger than range",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local pattern = {"a", "b", "c", "d", "e", "f"}
							ExtendedTableLibrary.fillWithPattern(array, pattern, 2, 4)
							local expected = {1, "a", "b", "c", 5}
							assert(deepEqual(array, expected), "Fill with pattern larger than range failed")
						end,
					},
					{
						Name = "Fill with start index only",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local pattern = {"x", "y"}
							ExtendedTableLibrary.fillWithPattern(array, pattern, 3)
							local expected = {1, 2, "x", "y", "x"}
							assert(deepEqual(array, expected), "Fill with start index only failed")
						end,
					},
					{
						Name = "Fill empty array with pattern",
						Function = function()
							local array = {}
							local pattern = {"a", "b"}
							ExtendedTableLibrary.fillWithPattern(array, pattern)
							local expected = {}
							assert(deepEqual(array, expected), "Fill empty array should not change it")
						end,
					},
					{
						Name = "Fill single element array with pattern",
						Function = function()
							local array = {1}
							local pattern = {"x", "y", "z"}
							ExtendedTableLibrary.fillWithPattern(array, pattern)
							local expected = {"x"}
							assert(deepEqual(array, expected), "Fill single element array with pattern failed")
						end,
					},
				},
			},

			-- reverseArray tests
			{
				Name = "reverseArray",
				TestCases = {
					{
						Name = "Reverse odd length array",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.reverseArray(array)
							local expected = {5, 4, 3, 2, 1}
							assert(deepEqual(array, expected), "Reverse odd length array failed")
						end,
					},
					{
						Name = "Reverse even length array",
						Function = function()
							local array = {1, 2, 3, 4}
							ExtendedTableLibrary.reverseArray(array)
							local expected = {4, 3, 2, 1}
							assert(deepEqual(array, expected), "Reverse even length array failed")
						end,
					},
					{
						Name = "Reverse single element array",
						Function = function()
							local array = {"only"}
							ExtendedTableLibrary.reverseArray(array)
							local expected = {"only"}
							assert(deepEqual(array, expected), "Reverse single element array failed")
						end,
					},
					{
						Name = "Reverse empty array",
						Function = function()
							local array = {}
							ExtendedTableLibrary.reverseArray(array)
							local expected = {}
							assert(deepEqual(array, expected), "Reverse empty array failed")
						end,
					},
					{
						Name = "Reverse string array",
						Function = function()
							local array = {"a", "b", "c", "d"}
							ExtendedTableLibrary.reverseArray(array)
							local expected = {"d", "c", "b", "a"}
							assert(deepEqual(array, expected), "Reverse string array failed")
						end,
					},
					{
						Name = "Reverse two element array",
						Function = function()
							local array = {10, 20}
							ExtendedTableLibrary.reverseArray(array)
							local expected = {20, 10}
							assert(deepEqual(array, expected), "Reverse two element array failed")
						end,
					},
				},
			},

			-- rotateArray tests
			{
				Name = "rotateArray",
				TestCases = {
					{
						Name = "Rotate right by 1",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.rotateArray(array, 1)
							local expected = {5, 1, 2, 3, 4}
							assert(deepEqual(array, expected), "Rotate right by 1 failed")
						end,
					},
					{
						Name = "Rotate left by 1",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.rotateArray(array, -1)
							local expected = {2, 3, 4, 5, 1}
							assert(deepEqual(array, expected), "Rotate left by 1 failed")
						end,
					},
					{
						Name = "Rotate right by 3",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.rotateArray(array, 3)
							local expected = {3, 4, 5, 1, 2}
							assert(deepEqual(array, expected), "Rotate right by 3 failed")
						end,
					},
					{
						Name = "Rotate left by 3",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.rotateArray(array, -3)
							local expected = {4, 5, 1, 2, 3}
							assert(deepEqual(array, expected), "Rotate left by 3 failed")
						end,
					},
					{
						Name = "Rotate by array length (no change)",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local original = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.rotateArray(array, 5)
							assert(deepEqual(array, original), "Rotate by array length should not change array")
						end,
					},
					{
						Name = "Rotate by zero (no change)",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local original = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.rotateArray(array, 0)
							assert(deepEqual(array, original), "Rotate by zero should not change array")
						end,
					},
					{
						Name = "Rotate empty array",
						Function = function()
							local array = {}
							ExtendedTableLibrary.rotateArray(array, 3)
							local expected = {}
							assert(deepEqual(array, expected), "Rotate empty array should not change it")
						end,
					},
					{
						Name = "Rotate single element array",
						Function = function()
							local array = {"only"}
							ExtendedTableLibrary.rotateArray(array, 5)
							local expected = {"only"}
							assert(deepEqual(array, expected), "Rotate single element array should not change it")
						end,
					},
					{
						Name = "Rotate by large positive number",
						Function = function()
							local array = {1, 2, 3}
							ExtendedTableLibrary.rotateArray(array, 7) -- 7 % 3 = 1
							local expected = {3, 1, 2}
							assert(deepEqual(array, expected), "Rotate by large positive number failed")
						end,
					},
					{
						Name = "Rotate by large negative number",
						Function = function()
							local array = {1, 2, 3}
							ExtendedTableLibrary.rotateArray(array, -7) -- -7 % 3 = -1
							local expected = {2, 3, 1}
							assert(deepEqual(array, expected), "Rotate by large negative number failed")
						end,
					},
				},
			},

			-- sliceArray tests
			{
				Name = "sliceArray",
				TestCases = {
					{
						Name = "Slice entire array",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sliceArray(array)
							local expected = {1, 2, 3, 4, 5}
							assert(deepEqual(result, expected), "Slice entire array failed")
							assert(result ~= array, "Slice should return new array")
						end,
					},
					{
						Name = "Slice with start and end index",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sliceArray(array, 2, 4)
							local expected = {2, 3, 4}
							assert(deepEqual(result, expected), "Slice with start and end index failed")
						end,
					},
					{
						Name = "Slice with start index only",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sliceArray(array, 3)
							local expected = {3, 4, 5}
							assert(deepEqual(result, expected), "Slice with start index only failed")
						end,
					},
					{
						Name = "Slice with end index only",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sliceArray(array, nil, 3)
							local expected = {1, 2, 3}
							assert(deepEqual(result, expected), "Slice with end index only failed")
						end,
					},
					{
						Name = "Slice single element",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sliceArray(array, 3, 3)
							local expected = {3}
							assert(deepEqual(result, expected), "Slice single element failed")
						end,
					},
					{
						Name = "Slice empty range",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sliceArray(array, 3, 2)
							local expected = {}
							assert(deepEqual(result, expected), "Slice empty range should return empty array")
						end,
					},
					{
						Name = "Slice empty array",
						Function = function()
							local array = {}
							local result = ExtendedTableLibrary.sliceArray(array)
							local expected = {}
							assert(deepEqual(result, expected), "Slice empty array failed")
						end,
					},
					{
						Name = "Slice beyond array bounds",
						Function = function()
							local array = {1, 2, 3}
							local result = ExtendedTableLibrary.sliceArray(array, 2, 10)
							local expected = {2, 3}
							assert(deepEqual(result, expected), "Slice beyond bounds should clamp to array size")
						end,
					},
					{
						Name = "Slice with start index beyond bounds",
						Function = function()
							local array = {1, 2, 3}
							local result = ExtendedTableLibrary.sliceArray(array, 5, 10)
							local expected = {}
							assert(deepEqual(result, expected), "Slice with start beyond bounds should return empty array")
						end,
					},
				},
			},

			-- shuffleArray tests
			{
				Name = "shuffleArray",
				TestCases = {
					{
						Name = "Shuffle array elements",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local original = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.shuffleArray(array)

							-- Check that all original elements are still present
							local originalSet = {}
							for _, v in original do
								originalSet[v] = true
							end

							local shuffledSet = {}
							for _, v in array do
								shuffledSet[v] = true
							end

							assert(deepEqual(originalSet, shuffledSet), "Shuffle should preserve all elements")
							assert(#array == #original, "Shuffle should preserve array length")
						end,
					},
					{
						Name = "Shuffle single element array",
						Function = function()
							local array = {"only"}
							local expected = {"only"}
							ExtendedTableLibrary.shuffleArray(array)
							assert(deepEqual(array, expected), "Single element array should remain unchanged")
						end,
					},
					{
						Name = "Shuffle empty array",
						Function = function()
							local array = {}
							local expected = {}
							ExtendedTableLibrary.shuffleArray(array)
							assert(deepEqual(array, expected), "Empty array should remain unchanged")
						end,
					},
					{
						Name = "Shuffle two element array",
						Function = function()
							local array = {1, 2}
							ExtendedTableLibrary.shuffleArray(array)

							-- Should contain both elements
							local hasOne = false
							local hasTwo = false
							for _, v in array do
								if v == 1 then hasOne = true end
								if v == 2 then hasTwo = true end
							end

							assert(hasOne and hasTwo, "Both elements should be present after shuffle")
							assert(#array == 2, "Array length should remain 2")
						end,
					},
					{
						Name = "Shuffle preserves element count",
						Function = function()
							local array = {1, 1, 2, 2, 3}
							ExtendedTableLibrary.shuffleArray(array)

							-- Count occurrences
							local counts = {}
							for _, v in array do
								counts[v] = (counts[v] or 0) + 1
							end

							assert(counts[1] == 2, "Should have 2 ones")
							assert(counts[2] == 2, "Should have 2 twos")
							assert(counts[3] == 1, "Should have 1 three")
						end,
					},
				},
			},

			-- sampleArray tests
			{
				Name = "sampleArray",
				TestCases = {
					{
						Name = "Sample without duplicates",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sampleArray(array, 3, false)

							assert(#result == 3, "Should sample exactly 3 elements")

							-- Check that all sampled elements are from original array
							local originalSet = {}
							for _, v in array do
								originalSet[v] = true
							end

							for _, v in result do
								assert(originalSet[v], `Sampled element {v} should be from original array`)
							end

							-- Check no duplicates
							local sampledSet = {}
							for _, v in result do
								assert(not sampledSet[v], `Element {v} should not be duplicated`)
								sampledSet[v] = true
							end
						end,
					},
					{
						Name = "Sample with duplicates allowed",
						Function = function()
							local array = {1, 2}
							local result = ExtendedTableLibrary.sampleArray(array, 5, true)

							assert(#result == 5, "Should sample exactly 5 elements")

							-- All elements should be from original array
							for _, v in result do
								assert(v == 1 or v == 2, `Sampled element {v} should be 1 or 2`)
							end
						end,
					},
					{
						Name = "Sample entire array",
						Function = function()
							local array = {1, 2, 3}
							local result = ExtendedTableLibrary.sampleArray(array, 3, false)

							assert(#result == 3, "Should sample exactly 3 elements")

							-- Should contain all elements (in some order)
							local originalSet = {}
							for _, v in array do
								originalSet[v] = true
							end

							local sampledSet = {}
							for _, v in result do
								sampledSet[v] = true
							end

							assert(deepEqual(originalSet, sampledSet), "Should sample all unique elements")
						end,
					},
					{
						Name = "Sample zero elements",
						Function = function()
							local array = {1, 2, 3}
							local result = ExtendedTableLibrary.sampleArray(array, 0, false)
							local expected = {}
							assert(deepEqual(result, expected), "Sample size 0 should return empty array")
						end,
					},
					{
						Name = "Sample single element",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sampleArray(array, 1, false)

							assert(#result == 1, "Should sample exactly 1 element")

							-- Element should be from original array
							local originalSet = {}
							for _, v in array do
								originalSet[v] = true
							end

							assert(originalSet[result[1]], "Sampled element should be from original array")
						end,
					},
					{
						Name = "Sample from single element array",
						Function = function()
							local array = {"only"}
							local result = ExtendedTableLibrary.sampleArray(array, 1, false)
							local expected = {"only"}
							assert(deepEqual(result, expected), "Sample from single element should return that element")
						end,
					},
				},
			},

			-- sampleValue tests
			{
				Name = "sampleValue",
				TestCases = {
					{
						Name = "Sample from entire array",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sampleValue(array)

							-- Result should be one of the array elements
							local found = false
							for _, v in array do
								if v == result then
									found = true
									break
								end
							end
							assert(found, `Sampled value {result} should be from array`)
						end,
					},
					{
						Name = "Sample with start and end index",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sampleValue(array, 2, 4)

							-- Result should be from indices 2-4 (values 2, 3, 4)
							assert(result >= 2 and result <= 4, `Sampled value {result} should be between 2 and 4`)
						end,
					},
					{
						Name = "Sample with start index only",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sampleValue(array, 3)

							-- Result should be from index 3 to end (values 3, 4, 5)
							assert(result >= 3 and result <= 5, `Sampled value {result} should be between 3 and 5`)
						end,
					},
					{
						Name = "Sample with end index only",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sampleValue(array, nil, 3)

							-- Result should be from start to index 3 (values 1, 2, 3)
							assert(result >= 1 and result <= 3, `Sampled value {result} should be between 1 and 3`)
						end,
					},
					{
						Name = "Sample single element from range",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.sampleValue(array, 3, 3)

							-- Should return exactly the element at index 3
							assert(result == 3, `Sampled value should be 3, got {result}`)
						end,
					},
					{
						Name = "Sample from single element array",
						Function = function()
							local array = {"only"}
							local result = ExtendedTableLibrary.sampleValue(array)

							assert(result == "only", `Sampled value should be "only", got {result}`)
						end,
					},
					{
						Name = "Sample string values",
						Function = function()
							local array = {"apple", "banana", "cherry"}
							local result = ExtendedTableLibrary.sampleValue(array)

							-- Result should be one of the string values
							local validValues = {apple = true, banana = true, cherry = true}
							assert(validValues[result], `Sampled value {result} should be one of the array strings`)
						end,
					},
				},
			},

			-- removeDuplicate tests
			{
				Name = "removeDuplicate",
				TestCases = {
					{
						Name = "Remove duplicates from array",
						Function = function()
							local array = {1, 2, 2, 3, 1, 4, 3, 5}
							local result = ExtendedTableLibrary.removeDuplicate(array)
							local expected = {1, 2, 3, 4, 5}
							assert(deepEqual(result, expected), "Remove duplicates failed")
						end,
					},
					{
						Name = "Remove duplicates with custom by function",
						Function = function()
							local array = {"apple", "banana", "apricot", "cherry", "avocado"}
							local result = ExtendedTableLibrary.removeDuplicate(array, function(value)
								return string.sub(value, 1, 1) -- Group by first letter
							end)

							-- Should keep first occurrence of each starting letter
							assert(#result == 3, "Should have 3 unique starting letters")

							-- Check that we have one word starting with 'a', 'b', and 'c'
							local startingLetters = {}
							for _, word in result do
								local firstLetter = string.sub(word, 1, 1)
								startingLetters[firstLetter] = (startingLetters[firstLetter] or 0) + 1
							end

							assert(startingLetters.a == 1, "Should have exactly 1 word starting with 'a'")
							assert(startingLetters.b == 1, "Should have exactly 1 word starting with 'b'")
							assert(startingLetters.c == 1, "Should have exactly 1 word starting with 'c'")
							assert(result[1] == "apple", "First 'a' word should be 'apple'")
						end,
					},
					{
						Name = "Remove duplicates from array with no duplicates",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.removeDuplicate(array)
							local expected = {1, 2, 3, 4, 5}
							assert(deepEqual(result, expected), "Array with no duplicates should remain unchanged")
						end,
					},
					{
						Name = "Remove duplicates from empty array",
						Function = function()
							local array = {}
							local result = ExtendedTableLibrary.removeDuplicate(array)
							local expected = {}
							assert(deepEqual(result, expected), "Empty array should remain empty")
						end,
					},
					{
						Name = "Remove duplicates preserves order",
						Function = function()
							local array = {3, 1, 4, 1, 5, 9, 2, 6, 5, 3}
							local result = ExtendedTableLibrary.removeDuplicate(array)
							local expected = {3, 1, 4, 5, 9, 2, 6}
							assert(deepEqual(result, expected), "Order of first occurrences should be preserved")
						end,
					},
					{
						Name = "Remove duplicates from all same elements",
						Function = function()
							local array = {7, 7, 7, 7, 7}
							local result = ExtendedTableLibrary.removeDuplicate(array)
							local expected = {7}
							assert(deepEqual(result, expected), "All same elements should reduce to single element")
						end,
					},
				},
			},

			-- swapRemove tests
			{
				Name = "swapRemove",
				TestCases = {
					{
						Name = "Swap remove from middle",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.swapRemove(array, 3)

							assert(#array == 4, "Array length should be reduced by 1")
							assert(array[3] == 5, "Element at index 3 should be the last element (5)")

							-- Check that element 3 is no longer in the array
							local hasThree = false
							for _, v in array do
								if v == 3 then hasThree = true end
							end
							assert(not hasThree, "Original element 3 should be removed")
						end,
					},
					{
						Name = "Swap remove last element",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.swapRemove(array, 5)
							local expected = {1, 2, 3, 4}
							assert(deepEqual(array, expected), "Removing last element should just truncate")
						end,
					},
					{
						Name = "Swap remove first element",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							ExtendedTableLibrary.swapRemove(array, 1)

							assert(#array == 4, "Array length should be reduced by 1")
							assert(array[1] == 5, "First element should be replaced with last element")
						end,
					},
					{
						Name = "Swap remove from two element array",
						Function = function()
							local array = {1, 2}
							ExtendedTableLibrary.swapRemove(array, 1)
							local expected = {2}
							assert(deepEqual(array, expected), "Should have only second element remaining")
						end,
					},
					{
						Name = "Swap remove from single element array",
						Function = function()
							local array = {"only"}
							ExtendedTableLibrary.swapRemove(array, 1)
							local expected = {}
							assert(deepEqual(array, expected), "Single element array should become empty")
						end,
					},
				},
			},

			-- getAndRemove tests
			{
				Name = "getAndRemove",
				TestCases = {
					{
						Name = "Get and remove with normal method",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.getAndRemove(array, 3, false)

							assert(result == 3, "Should return the removed element")
							local expected = {1, 2, 4, 5}
							assert(deepEqual(array, expected), "Array should have element removed and others shifted")
						end,
					},
					{
						Name = "Get and remove with swap method",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.getAndRemove(array, 3, true)

							assert(result == 3, "Should return the removed element")
							assert(#array == 4, "Array length should be reduced by 1")
							assert(array[3] == 5, "Element at index 3 should be the last element")
						end,
					},
					{
						Name = "Get and remove first element",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.getAndRemove(array, 1)

							assert(result == 1, "Should return the first element")
							local expected = {2, 3, 4, 5}
							assert(deepEqual(array, expected), "Array should have first element removed")
						end,
					},
					{
						Name = "Get and remove last element",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.getAndRemove(array, 5)

							assert(result == 5, "Should return the last element")
							local expected = {1, 2, 3, 4}
							assert(deepEqual(array, expected), "Array should have last element removed")
						end,
					},
					{
						Name = "Get and remove out of bounds",
						Function = function()
							local array = {1, 2, 3}
							local result = ExtendedTableLibrary.getAndRemove(array, 5)

							assert(result == nil, "Should return nil for out of bounds index")
							local expected = {1, 2, 3}
							assert(deepEqual(array, expected), "Array should remain unchanged")
						end,
					},
					{
						Name = "Get and remove from single element array",
						Function = function()
							local array = {"only"}
							local result = ExtendedTableLibrary.getAndRemove(array, 1)

							assert(result == "only", "Should return the only element")
							local expected = {}
							assert(deepEqual(array, expected), "Array should become empty")
						end,
					},
				},
			},

			-- findAndRemove tests
			{
				Name = "findAndRemove",
				TestCases = {
					{
						Name = "Find and remove existing value",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.findAndRemove(array, 3)

							assert(result == true, "Should return true when value is found and removed")
							local expected = {1, 2, 4, 5}
							assert(deepEqual(array, expected), "Array should have value removed")
						end,
					},
					{
						Name = "Find and remove with swap method",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.findAndRemove(array, 3, true)

							assert(result == true, "Should return true when value is found and removed")
							assert(#array == 4, "Array length should be reduced by 1")

							-- Check that 3 is no longer in the array
							local hasThree = false
							for _, v in array do
								if v == 3 then hasThree = true end
							end
							assert(not hasThree, "Value 3 should be removed from array")
						end,
					},
					{
						Name = "Find and remove non-existing value",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local originalArray = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.findAndRemove(array, 10)

							assert(result == false, "Should return false when value is not found")
							assert(deepEqual(array, originalArray), "Array should remain unchanged")
						end,
					},
					{
						Name = "Find and remove first occurrence",
						Function = function()
							local array = {1, 2, 3, 2, 4}
							local result = ExtendedTableLibrary.findAndRemove(array, 2)

							assert(result == true, "Should return true when value is found")
							local expected = {1, 3, 2, 4}
							assert(deepEqual(array, expected), "Should remove first occurrence only")
						end,
					},
					{
						Name = "Find and remove from single element array",
						Function = function()
							local array = {"target"}
							local result = ExtendedTableLibrary.findAndRemove(array, "target")

							assert(result == true, "Should return true when value is found")
							local expected = {}
							assert(deepEqual(array, expected), "Array should become empty")
						end,
					},
					{
						Name = "Find and remove from empty array",
						Function = function()
							local array = {}
							local result = ExtendedTableLibrary.findAndRemove(array, "anything")

							assert(result == false, "Should return false for empty array")
							local expected = {}
							assert(deepEqual(array, expected), "Empty array should remain empty")
						end,
					},
					{
						Name = "Find and remove string values",
						Function = function()
							local array = {"apple", "banana", "cherry", "date"}
							local result = ExtendedTableLibrary.findAndRemove(array, "banana")

							assert(result == true, "Should return true when string is found")
							local expected = {"apple", "cherry", "date"}
							assert(deepEqual(array, expected), "String should be removed from array")
						end,
					},
				},
			},

			-- zipArray tests
			{
				Name = "zipArray",
				TestCases = {
					{
						Name = "Zip two arrays of equal length",
						Function = function()
							local arr1 = {1, 2, 3}
							local arr2 = {"a", "b", "c"}
							local result = ExtendedTableLibrary.zipArray(arr1, arr2)
							local expected = {{1, "a"}, {2, "b"}, {3, "c"}}
							assert(deepEqual(result, expected), "Zip two equal length arrays failed")
						end,
					},
					{
						Name = "Zip three arrays",
						Function = function()
							local arr1 = {1, 2, 3}
							local arr2 = {"a", "b", "c"}
							local arr3 = {true, false, true}
							local result = ExtendedTableLibrary.zipArray(arr1, arr2, arr3)
							local expected = {{1, "a", true}, {2, "b", false}, {3, "c", true}}
							assert(deepEqual(result, expected), "Zip three arrays failed")
						end,
					},
					{
						Name = "Zip arrays of different lengths",
						Function = function()
							local arr1 = {1, 2, 3, 4, 5}
							local arr2 = {"a", "b", "c"}
							local arr3 = {true, false}
							local result = ExtendedTableLibrary.zipArray(arr1, arr2, arr3)
							local expected = {{1, "a", true}, {2, "b", false}}
							assert(deepEqual(result, expected), "Should zip to length of shortest array")
						end,
					},
					{
						Name = "Zip single array",
						Function = function()
							local arr1 = {1, 2, 3}
							local result = ExtendedTableLibrary.zipArray(arr1)
							local expected = {{1}, {2}, {3}}
							assert(deepEqual(result, expected), "Zip single array failed")
						end,
					},
					{
						Name = "Zip with empty array",
						Function = function()
							local arr1 = {1, 2, 3}
							local arr2 = {}
							local result = ExtendedTableLibrary.zipArray(arr1, arr2)
							local expected = {}
							assert(deepEqual(result, expected), "Zip with empty array should return empty")
						end,
					},
					{
						Name = "Zip all empty arrays",
						Function = function()
							local arr1 = {}
							local arr2 = {}
							local result = ExtendedTableLibrary.zipArray(arr1, arr2)
							local expected = {}
							assert(deepEqual(result, expected), "Zip all empty arrays should return empty")
						end,
					},
				},
			},

			-- unzipArray tests
			{
				Name = "unzipArray",
				TestCases = {
					{
						Name = "Unzip array of pairs",
						Function = function()
							local zippedArray = {{1, "a"}, {2, "b"}, {3, "c"}}
							local result = ExtendedTableLibrary.unzipArray(zippedArray)
							local expected = {{1, 2, 3}, {"a", "b", "c"}}
							assert(deepEqual(result, expected), "Unzip array of pairs failed")
						end,
					},
					{
						Name = "Unzip array of triples",
						Function = function()
							local zippedArray = {{1, "a", true}, {2, "b", false}, {3, "c", true}}
							local result = ExtendedTableLibrary.unzipArray(zippedArray)
							local expected = {{1, 2, 3}, {"a", "b", "c"}, {true, false, true}}
							assert(deepEqual(result, expected), "Unzip array of triples failed")
						end,
					},
					{
						Name = "Unzip single tuple",
						Function = function()
							local zippedArray = {{1, "a", true}}
							local result = ExtendedTableLibrary.unzipArray(zippedArray)
							local expected = {{1}, {"a"}, {true}}
							assert(deepEqual(result, expected), "Unzip single tuple failed")
						end,
					},
					{
						Name = "Unzip empty array",
						Function = function()
							local zippedArray = {}
							local result = ExtendedTableLibrary.unzipArray(zippedArray)
							local expected = {}
							assert(deepEqual(result, expected), "Unzip empty array should return empty")
						end,
					},
					{
						Name = "Unzip single element tuples",
						Function = function()
							local zippedArray = {{1}, {2}, {3}}
							local result = ExtendedTableLibrary.unzipArray(zippedArray)
							local expected = {{1, 2, 3}}
							assert(deepEqual(result, expected), "Unzip single element tuples failed")
						end,
					},
					{
						Name = "Roundtrip zip-unzip",
						Function = function()
							local arr1 = {1, 2, 3}
							local arr2 = {"a", "b", "c"}
							local arr3 = {true, false, true}

							local zipped = ExtendedTableLibrary.zipArray(arr1, arr2, arr3)
							local unzipped = ExtendedTableLibrary.unzipArray(zipped)
							local expected = {arr1, arr2, arr3}

							assert(deepEqual(unzipped, expected), "Zip-unzip roundtrip failed")
						end,
					},
				},
			},

			-- partitionArray tests
			{
				Name = "partitionArray",
				TestCases = {
					{
						Name = "Partition array evenly",
						Function = function()
							local array = {1, 2, 3, 4, 5, 6}
							local result = ExtendedTableLibrary.partitionArray(array, 2)
							local expected = {{1, 2}, {3, 4}, {5, 6}}
							assert(deepEqual(result, expected), "Partition array evenly failed")
						end,
					},
					{
						Name = "Partition array with remainder",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.partitionArray(array, 2)
							local expected = {{1, 2}, {3, 4}, {5}}
							assert(deepEqual(result, expected), "Partition array with remainder failed")
						end,
					},
					{
						Name = "Partition with size 1",
						Function = function()
							local array = {1, 2, 3}
							local result = ExtendedTableLibrary.partitionArray(array, 1)
							local expected = {{1}, {2}, {3}}
							assert(deepEqual(result, expected), "Partition with size 1 failed")
						end,
					},
					{
						Name = "Partition with size larger than array",
						Function = function()
							local array = {1, 2, 3}
							local result = ExtendedTableLibrary.partitionArray(array, 5)
							local expected = {{1, 2, 3}}
							assert(deepEqual(result, expected), "Partition with large size should return single partition")
						end,
					},
					{
						Name = "Partition empty array",
						Function = function()
							local array = {}
							local result = ExtendedTableLibrary.partitionArray(array, 2)
							local expected = {}
							assert(deepEqual(result, expected), "Partition empty array should return empty")
						end,
					},
					{
						Name = "Partition with size 3",
						Function = function()
							local array = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
							local result = ExtendedTableLibrary.partitionArray(array, 3)
							local expected = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {10}}
							assert(deepEqual(result, expected), "Partition with size 3 failed")
						end,
					},
					{
						Name = "Partition single element array",
						Function = function()
							local array = {"only"}
							local result = ExtendedTableLibrary.partitionArray(array, 2)
							local expected = {{"only"}}
							assert(deepEqual(result, expected), "Partition single element array failed")
						end,
					},
				},
			},

			-- partitionArrayBy tests
			{
				Name = "partitionArrayBy",
				TestCases = {
					{
						Name = "Partition by even/odd",
						Function = function()
							local array = {1, 2, 3, 4, 5, 6}
							local truthy, falsy = ExtendedTableLibrary.partitionArrayBy(array, function(x)
								return x % 2 == 0
							end)
							local expectedTruthy = {2, 4, 6}
							local expectedFalsy = {1, 3, 5}
							assert(deepEqual(truthy, expectedTruthy), "Even partition failed")
							assert(deepEqual(falsy, expectedFalsy), "Odd partition failed")
						end,
					},
					{
						Name = "Partition by string length",
						Function = function()
							local array = {"a", "hello", "hi", "world", "test"}
							local truthy, falsy = ExtendedTableLibrary.partitionArrayBy(array, function(str)
								return string.len(str) > 3
							end)
							local expectedTruthy = {"hello", "world", "test"}
							local expectedFalsy = {"a", "hi"}
							assert(deepEqual(truthy, expectedTruthy), "Long string partition failed")
							assert(deepEqual(falsy, expectedFalsy), "Short string partition failed")
						end,
					},
					{
						Name = "Partition all true",
						Function = function()
							local array = {2, 4, 6, 8}
							local truthy, falsy = ExtendedTableLibrary.partitionArrayBy(array, function(x)
								return x % 2 == 0
							end)
							local expectedTruthy = {2, 4, 6, 8}
							local expectedFalsy = {}
							assert(deepEqual(truthy, expectedTruthy), "All true partition failed")
							assert(deepEqual(falsy, expectedFalsy), "False partition should be empty")
						end,
					},
					{
						Name = "Partition all false",
						Function = function()
							local array = {1, 3, 5, 7}
							local truthy, falsy = ExtendedTableLibrary.partitionArrayBy(array, function(x)
								return x % 2 == 0
							end)
							local expectedTruthy = {}
							local expectedFalsy = {1, 3, 5, 7}
							assert(deepEqual(truthy, expectedTruthy), "True partition should be empty")
							assert(deepEqual(falsy, expectedFalsy), "All false partition failed")
						end,
					},
					{
						Name = "Partition empty table",
						Function = function()
							local tbl = {}
							local truthy, falsy = ExtendedTableLibrary.partitionArrayBy(tbl, function(x)
								return x > 0
							end)
							local expectedTruthy = {}
							local expectedFalsy = {}
							assert(deepEqual(truthy, expectedTruthy), "Empty table true partition should be empty")
							assert(deepEqual(falsy, expectedFalsy), "Empty table false partition should be empty")
						end,
					},
					{
						Name = "Partition single element true",
						Function = function()
							local array = {5}
							local truthy, falsy = ExtendedTableLibrary.partitionArrayBy(array, function(x)
								return x > 3
							end)
							local expectedTruthy = {5}
							local expectedFalsy = {}
							assert(deepEqual(truthy, expectedTruthy), "Single element true partition failed")
							assert(deepEqual(falsy, expectedFalsy), "Single element false partition should be empty")
						end,
					},
					{
						Name = "Partition single element false",
						Function = function()
							local array = {2}
							local truthy, falsy = ExtendedTableLibrary.partitionArrayBy(array, function(x)
								return x > 3
							end)
							local expectedTruthy = {}
							local expectedFalsy = {2}
							assert(deepEqual(truthy, expectedTruthy), "Single element true partition should be empty")
							assert(deepEqual(falsy, expectedFalsy), "Single element false partition failed")
						end,
					},
					{
						Name = "Partition preserves order",
						Function = function()
							local array = {5, 1, 8, 2, 9, 3}
							local truthy, falsy = ExtendedTableLibrary.partitionArrayBy(array, function(x)
								return x > 4
							end)
							local expectedTruthy = {5, 8, 9}
							local expectedFalsy = {1, 2, 3}
							assert(deepEqual(truthy, expectedTruthy), "True partition order failed")
							assert(deepEqual(falsy, expectedFalsy), "False partition order failed")
						end,
					},
				},
			},

			-- binarySearch tests
			{
				Name = "binarySearch",
				TestCases = {
					{
						Name = "Find value in sorted numeric array",
						Function = function()
							local sortedArray = {1, 3, 5, 7, 9, 11, 13}
							assert(ExtendedTableLibrary.binarySearch(sortedArray, 7) == 4, "Should find 7 at index 4")
							assert(ExtendedTableLibrary.binarySearch(sortedArray, 1) == 1, "Should find 1 at index 1")
							assert(ExtendedTableLibrary.binarySearch(sortedArray, 13) == 7, "Should find 13 at index 7")
							assert(ExtendedTableLibrary.binarySearch(sortedArray, 5) == 3, "Should find 5 at index 3")
						end,
					},
					{
						Name = "Value not found in sorted array",
						Function = function()
							local sortedArray = {1, 3, 5, 7, 9, 11, 13}
							assert(ExtendedTableLibrary.binarySearch(sortedArray, 2) == nil, "Should not find 2")
							assert(ExtendedTableLibrary.binarySearch(sortedArray, 0) == nil, "Should not find 0")
							assert(ExtendedTableLibrary.binarySearch(sortedArray, 15) == nil, "Should not find 15")
							assert(ExtendedTableLibrary.binarySearch(sortedArray, 8) == nil, "Should not find 8")
						end,
					},
					{
						Name = "Single element array",
						Function = function()
							local singleArray = {42}
							assert(ExtendedTableLibrary.binarySearch(singleArray, 42) == 1, "Should find 42 at index 1")
							assert(ExtendedTableLibrary.binarySearch(singleArray, 41) == nil, "Should not find 41")
							assert(ExtendedTableLibrary.binarySearch(singleArray, 43) == nil, "Should not find 43")
						end,
					},
					{
						Name = "Empty array",
						Function = function()
							local emptyArray = {}
							assert(ExtendedTableLibrary.binarySearch(emptyArray, 1) == nil, "Should not find anything in empty array")
							assert(ExtendedTableLibrary.binarySearch(emptyArray, "test") == nil, "Should not find string in empty array")
						end,
					},
					{
						Name = "Array with duplicate values",
						Function = function()
							local arrayWithDuplicates = {1, 2, 2, 2, 5, 6, 7}
							local foundIndex = ExtendedTableLibrary.binarySearch(arrayWithDuplicates, 2)
							assert(foundIndex ~= nil, "Should find 2 in array with duplicates")
							assert(foundIndex >= 2 and foundIndex <= 4, "Should find 2 at one of the valid indices (2, 3, or 4)")
							assert(arrayWithDuplicates[foundIndex] == 2, "Found index should contain the value 2")
						end,
					},
					{
						Name = "String array alphabetical search",
						Function = function()
							local sortedStrings = {"apple", "banana", "cherry", "date", "elderberry"}
							assert(ExtendedTableLibrary.binarySearch(sortedStrings, "cherry") == 3, "Should find 'cherry' at index 3")
							assert(ExtendedTableLibrary.binarySearch(sortedStrings, "apple") == 1, "Should find 'apple' at index 1")
							assert(ExtendedTableLibrary.binarySearch(sortedStrings, "elderberry") == 5, "Should find 'elderberry' at index 5")
							assert(ExtendedTableLibrary.binarySearch(sortedStrings, "blueberry") == nil, "Should not find 'blueberry'")
						end,
					},
					{
						Name = "Custom comparator for numeric values",
						Function = function()
							local sortedArray = {1, 3, 5, 7, 9, 11, 13}
							local numericComparator = function(a, b)
								if a < b then return -1
								elseif a > b then return 1
								else return 0 end
							end

							assert(ExtendedTableLibrary.binarySearch(sortedArray, 7, numericComparator) == 4, "Should find 7 at index 4 with custom comparator")
							assert(ExtendedTableLibrary.binarySearch(sortedArray, 2, numericComparator) == nil, "Should not find 2 with custom comparator")
						end,
					},
					{
						Name = "Custom comparator for reverse-sorted array",
						Function = function()
							local reverseSortedArray = {13, 11, 9, 7, 5, 3, 1}
							local reverseComparator = function(a, b)
								if a > b then return -1
								elseif a < b then return 1
								else return 0 end
							end

							assert(ExtendedTableLibrary.binarySearch(reverseSortedArray, 7, reverseComparator) == 4, "Should find 7 at index 4 in reverse-sorted array")
							assert(ExtendedTableLibrary.binarySearch(reverseSortedArray, 13, reverseComparator) == 1, "Should find 13 at index 1 in reverse-sorted array")
							assert(ExtendedTableLibrary.binarySearch(reverseSortedArray, 1, reverseComparator) == 7, "Should find 1 at index 7 in reverse-sorted array")
							assert(ExtendedTableLibrary.binarySearch(reverseSortedArray, 8, reverseComparator) == nil, "Should not find 8 in reverse-sorted array")
						end,
					},
					{
						Name = "Custom comparator for case-insensitive string search",
						Function = function()
							local mixedCaseStrings = {"Apple", "Banana", "Cherry", "Date", "Elderberry"}
							local caseInsensitiveComparator = function(a, b)
								local lowerA = string.lower(a)
								local lowerB = string.lower(b)
								if lowerA < lowerB then return -1
								elseif lowerA > lowerB then return 1
								else return 0 end
							end

							assert(ExtendedTableLibrary.binarySearch(mixedCaseStrings, "cherry", caseInsensitiveComparator) == 3, "Should find 'cherry' matching 'Cherry' case-insensitively")
							assert(ExtendedTableLibrary.binarySearch(mixedCaseStrings, "BANANA", caseInsensitiveComparator) == 2, "Should find 'BANANA' matching 'Banana' case-insensitively")
							assert(ExtendedTableLibrary.binarySearch(mixedCaseStrings, "grape", caseInsensitiveComparator) == nil, "Should not find 'grape' case-insensitively")
						end,
					},
					{
						Name = "Large sorted array performance test",
						Function = function()
							local largeArray = {}
							for i = 1, 1000 do
								largeArray[i] = i * 2  -- Even numbers: 2, 4, 6, ..., 2000
							end

							assert(ExtendedTableLibrary.binarySearch(largeArray, 100) == 50, "Should find 100 at index 50 in large array")
							assert(ExtendedTableLibrary.binarySearch(largeArray, 2) == 1, "Should find 2 at index 1 in large array")
							assert(ExtendedTableLibrary.binarySearch(largeArray, 2000) == 1000, "Should find 2000 at index 1000 in large array")
							assert(ExtendedTableLibrary.binarySearch(largeArray, 999) == nil, "Should not find odd number 999 in large array")
							assert(ExtendedTableLibrary.binarySearch(largeArray, 2001) == nil, "Should not find 2001 in large array")
						end,
					},
					{
						Name = "Complex object search with custom comparator",
						Function = function()
							local people = {
								{name = "Alice", age = 25},
								{name = "Bob", age = 30},
								{name = "Charlie", age = 35},
								{name = "Dave", age = 40},
								{name = "Eve", age = 45}
							}

							local ageComparator = function(person, targetAge)
								if person.age < targetAge then return -1
								elseif person.age > targetAge then return 1
								else return 0 end
							end

							assert(ExtendedTableLibrary.binarySearch(people, 35, ageComparator) == 3, "Should find person with age 35 at index 3")
							assert(ExtendedTableLibrary.binarySearch(people, 25, ageComparator) == 1, "Should find person with age 25 at index 1")
							assert(ExtendedTableLibrary.binarySearch(people, 45, ageComparator) == 5, "Should find person with age 45 at index 5")
							assert(ExtendedTableLibrary.binarySearch(people, 33, ageComparator) == nil, "Should not find person with age 33")
						end,
					},
					{
						Name = "Edge case: All elements are the same",
						Function = function()
							local sameValues = {5, 5, 5, 5, 5}
							local foundIndex = ExtendedTableLibrary.binarySearch(sameValues, 5)
							assert(foundIndex ~= nil, "Should find 5 in array of all 5s")
							assert(foundIndex >= 1 and foundIndex <= 5, "Should find 5 at a valid index")
							assert(sameValues[foundIndex] == 5, "Found index should contain the value 5")
							assert(ExtendedTableLibrary.binarySearch(sameValues, 4) == nil, "Should not find 4 in array of all 5s")
							assert(ExtendedTableLibrary.binarySearch(sameValues, 6) == nil, "Should not find 6 in array of all 5s")
						end,
					},
				},
			},
		}
	},

	[4] = {
		Name = "Inspection & Metadata",

		TestCases = {

			-- getKeys tests
			{
				Name = "getKeys",
				TestCases = {
					{
						Name = "Get keys from simple hash table",
						Function = function()
							local hashTable = {a = 1, b = 2, c = 3}
							local keys = ExtendedTableLibrary.getKeys(hashTable)

							-- Sort the keys for consistent comparison since iteration order is not guaranteed
							ExtendedTableLibrary.sort(keys)
							assert(deepEqual(keys, {"a", "b", "c"}), "Should return all string keys")
						end,
					},
					{
						Name = "Get keys from array table",
						Function = function()
							local arrayTable = {10, 20, 30, 40}
							local keys = ExtendedTableLibrary.getKeys(arrayTable)

							-- Sort the keys for consistent comparison
							ExtendedTableLibrary.sort(keys)
							assert(deepEqual(keys, {1, 2, 3, 4}), "Should return numeric indices")
						end,
					},
					{
						Name = "Get keys from mixed table",
						Function = function()
							local mixedTable = {10, 20, a = "hello", b = "world", [5] = 50}
							local keys = ExtendedTableLibrary.getKeys(mixedTable)

							-- Sort the keys for consistent comparison
							ExtendedTableLibrary.sort(keys, function(a, b)
								if type(a) == type(b) then
									return a < b
								else
									return type(a) < type(b)  -- Numbers before strings
								end
							end)
							assert(deepEqual(keys, {1, 2, 5, "a", "b"}), "Should return all keys from mixed table")
						end,
					},
					{
						Name = "Get keys from empty table",
						Function = function()
							local emptyTable = {}
							local keys = ExtendedTableLibrary.getKeys(emptyTable)
							assert(deepEqual(keys, {}), "Should return empty array for empty table")
						end,
					},
					{
						Name = "Get keys with numeric keys",
						Function = function()
							local numericKeyTable = {[100] = "a", [200] = "b", [50] = "c"}
							local keys = ExtendedTableLibrary.getKeys(numericKeyTable)

							ExtendedTableLibrary.sort(keys)
							assert(deepEqual(keys, {50, 100, 200}), "Should return all numeric keys")
						end,
					},
					{
						Name = "Get keys with various key types",
						Function = function()
							local obj = {}
							local variedTable = {
								[1] = "one",
								["string"] = "value",
								[true] = "boolean key",
								[obj] = "object key"
							}
							local keys = ExtendedTableLibrary.getKeys(variedTable)

							-- Check that we have the right number of keys
							assert(#keys == 4, "Should have 4 keys")

							-- Check that all expected keys are present
							local hasNumber, hasString, hasBoolean, hasObject = false, false, false, false
							for _, key in keys do
								if key == 1 then hasNumber = true
								elseif key == "string" then hasString = true
								elseif key == true then hasBoolean = true
								elseif key == obj then hasObject = true
								end
							end

							assert(hasNumber and hasString and hasBoolean and hasObject, "Should contain all key types")
						end,
					},
					{
						Name = "Get keys preserves order for array part",
						Function = function()
							local orderedArray = {100, 200, 300}
							local keys = ExtendedTableLibrary.getKeys(orderedArray)

							-- Array keys should maintain order 1, 2, 3
							assert(deepEqual(keys, {1, 2, 3}), "Should preserve array index order")
						end,
					},
				},
			},

			-- getValues tests
			{
				Name = "getValues",
				TestCases = {
					{
						Name = "Get values from simple hash table",
						Function = function()
							local hashTable = {a = 10, b = 20, c = 30}
							local values = ExtendedTableLibrary.getValues(hashTable)

							-- Sort the values for consistent comparison since iteration order is not guaranteed
							ExtendedTableLibrary.sort(values)
							assert(deepEqual(values, {10, 20, 30}), "Should return all values")
						end,
					},
					{
						Name = "Get values from array table",
						Function = function()
							local arrayTable = {"apple", "banana", "cherry"}
							local values = ExtendedTableLibrary.getValues(arrayTable)

							assert(deepEqual(values, {"apple", "banana", "cherry"}), "Should return array values in order")
						end,
					},
					{
						Name = "Get values from mixed table",
						Function = function()
							local mixedTable = {"first", "second", x = "extra", y = "more"}
							local values = ExtendedTableLibrary.getValues(mixedTable)

							-- Check that we have the right number of values
							assert(#values == 4, "Should have 4 values")

							-- Check that all expected values are present
							local hasFirst, hasSecond, hasExtra, hasMore = false, false, false, false
							for _, value in values do
								if value == "first" then hasFirst = true
								elseif value == "second" then hasSecond = true
								elseif value == "extra" then hasExtra = true
								elseif value == "more" then hasMore = true
								end
							end

							assert(hasFirst and hasSecond and hasExtra and hasMore, "Should contain all values")
						end,
					},
					{
						Name = "Get values from empty table",
						Function = function()
							local emptyTable = {}
							local values = ExtendedTableLibrary.getValues(emptyTable)
							assert(deepEqual(values, {}), "Should return empty array for empty table")
						end,
					},
					{
						Name = "Get values with duplicate values",
						Function = function()
							local duplicateTable = {a = 100, b = 200, c = 100, d = 200}
							local values = ExtendedTableLibrary.getValues(duplicateTable)

							-- Sort for consistent comparison
							ExtendedTableLibrary.sort(values)
							assert(deepEqual(values, {100, 100, 200, 200}), "Should return all values including duplicates")
						end,
					},
					{
						Name = "Get values with various value types",
						Function = function()
							local obj = {}
							local variedTable = {
								a = 42,
								b = "hello",
								c = true,
								d = obj,
								e = nil  -- nil values won't be included
							}
							local values = ExtendedTableLibrary.getValues(variedTable)

							-- Check that we have the right number of values (excluding nil)
							assert(#values == 4, "Should have 4 values (nil excluded)")

							-- Check that all expected values are present
							local hasNumber, hasString, hasBoolean, hasObject = false, false, false, false
							for _, value in values do
								if value == 42 then hasNumber = true
								elseif value == "hello" then hasString = true
								elseif value == true then hasBoolean = true
								elseif value == obj then hasObject = true
								end
							end

							assert(hasNumber and hasString and hasBoolean and hasObject, "Should contain all value types")
						end,
					},
					{
						Name = "Get values preserves order for array part",
						Function = function()
							local orderedArray = {"first", "second", "third"}
							local values = ExtendedTableLibrary.getValues(orderedArray)

							-- Array values should maintain order
							assert(deepEqual(values, {"first", "second", "third"}), "Should preserve array value order")
						end,
					},
					{
						Name = "Get values with nested tables",
						Function = function()
							local nestedTable = {
								a = {x = 1},
								b = {y = 2},
								c = {z = 3}
							}
							local values = ExtendedTableLibrary.getValues(nestedTable)

							-- Check that we have the right number of nested tables
							assert(#values == 3, "Should have 3 nested table values")

							-- Verify that all values are tables
							for _, value in values do
								assert(type(value) == "table", "All values should be tables")
							end
						end,
					},
				},
			},

			-- isContiguousArray tests
			{
				Name = "isContiguousArray",
				TestCases = {
					{
						Name = "Contiguous array with sequential indices",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == true, "Sequential array should be contiguous")
						end,
					},
					{
						Name = "Empty array is contiguous",
						Function = function()
							local array = {}
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == true, "Empty array should be contiguous")
						end,
					},
					{
						Name = "Single element array is contiguous",
						Function = function()
							local array = {42}
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == true, "Single element array should be contiguous")
						end,
					},
					{
						Name = "Array with nil hole is not contiguous",
						Function = function()
							local array = {1, 2, nil, 4, 5}
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == false, "Array with nil hole should not be contiguous")
						end,
					},
					{
						Name = "Sparse array with gaps is not contiguous",
						Function = function()
							local array = {[1] = "a", [3] = "c", [5] = "e"}
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == false, "Sparse array should not be contiguous")
						end,
					},
					{
						Name = "Array with string keys is not contiguous",
						Function = function()
							local array = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == false, "Hash table with string keys should not be contiguous")
						end,
					},
					{
						Name = "Mixed array/hash table is not contiguous",
						Function = function()
							local array = {1, 2, 3, a = "hello", b = "world"}
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == false, "Mixed table should not be contiguous")
						end,
					},
					{
						Name = "Array starting from index 0 is not contiguous",
						Function = function()
							local array = {[0] = "zero", [1] = "one", [2] = "two"}
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == false, "Array starting from 0 should not be contiguous")
						end,
					},
					{
						Name = "Array with negative indices is not contiguous",
						Function = function()
							local array = {[-1] = "negative", [1] = "positive"}
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == false, "Array with negative indices should not be contiguous")
						end,
					},
					{
						Name = "Array with explicit nil at end",
						Function = function()
							local array = {1, 2, 3}
							array[4] = nil  -- Explicitly set nil
							local result = ExtendedTableLibrary.isContiguousArray(array)
							assert(result == true, "Array with trailing nil should still be contiguous")
						end,
					},
				},
			},

			-- isSparseArray tests
			{
				Name = "isSparseArray",
				TestCases = {
					{
						Name = "Sparse array with gaps",
						Function = function()
							local array = {[1] = "a", [3] = "c", [5] = "e"}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == true, "Array with gaps should be sparse")
						end,
					},
					{
						Name = "Contiguous array is not sparse",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == false, "Contiguous array should not be sparse")
						end,
					},
					{
						Name = "Empty array is not sparse",
						Function = function()
							local array = {}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == false, "Empty array should not be sparse")
						end,
					},
					{
						Name = "Single element array is not sparse",
						Function = function()
							local array = {42}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == false, "Single element array should not be sparse")
						end,
					},
					{
						Name = "Array with string keys is not sparse (not an array)",
						Function = function()
							local array = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == false, "Hash table with string keys should not be considered sparse array")
						end,
					},
					{
						Name = "Array with mixed key types is not sparse (not pure array)",
						Function = function()
							local array = {1, 2, 3, a = "hello"}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == false, "Mixed table should not be considered sparse array")
						end,
					},
					{
						Name = "Array with nil hole in middle is sparse",
						Function = function()
							local array = {1, 2, nil, 4, 5}
							array[6] = 6  -- Extend beyond the nil
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == true, "Array with nil hole should be sparse")
						end,
					},
					{
						Name = "Array starting from higher index is sparse",
						Function = function()
							local array = {[5] = "five", [6] = "six", [7] = "seven"}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == true, "Array not starting from 1 should be sparse")
						end,
					},
					{
						Name = "Array with large gaps is sparse",
						Function = function()
							local array = {[1] = "one", [100] = "hundred", [1000] = "thousand"}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == true, "Array with large gaps should be sparse")
						end,
					},
					{
						Name = "Array with negative indices is not sparse (not valid array)",
						Function = function()
							local array = {[-1] = "negative", [1] = "positive", [3] = "gap"}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == false, "Array with negative indices should not be considered sparse array")
						end,
					},
					{
						Name = "Array with zero index is not sparse (not valid array)",
						Function = function()
							local array = {[0] = "zero", [2] = "two", [4] = "four"}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == false, "Array with zero index should not be considered sparse array")
						end,
					},
					{
						Name = "Array with fractional indices is not sparse (not valid array)",
						Function = function()
							local array = {[1.5] = "one-half", [2.5] = "two-half"}
							local result = ExtendedTableLibrary.isSparseArray(array)
							assert(result == false, "Array with fractional indices should not be considered sparse array")
						end,
					},
				},
			},

			-- isArray tests
			{
				Name = "isArray",
				TestCases = {
					{
						Name = "Contiguous array with sequential indices",
						Function = function()
							local array = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.isArray(array)
							assert(result == true, "Sequential array should be an array")
						end,
					},
					{
						Name = "Empty table is an array",
						Function = function()
							local array = {}
							local result = ExtendedTableLibrary.isArray(array)
							assert(result == true, "Empty table should be considered an array")
						end,
					},
					{
						Name = "Single element array",
						Function = function()
							local array = {42}
							local result = ExtendedTableLibrary.isArray(array)
							assert(result == true, "Single element array should be an array")
						end,
					},
					{
						Name = "Sparse array with positive integer keys",
						Function = function()
							local array = {[1] = "a", [3] = "c", [5] = "e"}
							local result = ExtendedTableLibrary.isArray(array)
							assert(result == true, "Sparse array with positive integer keys should be an array")
						end,
					},
					{
						Name = "Array with large index gaps",
						Function = function()
							local array = {[1] = "one", [100] = "hundred", [1000] = "thousand"}
							local result = ExtendedTableLibrary.isArray(array)
							assert(result == true, "Array with large gaps should still be an array")
						end,
					},
					{
						Name = "Hash table with string keys is not an array",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.isArray(table)
							assert(result == false, "Hash table with string keys should not be an array")
						end,
					},
					{
						Name = "Mixed table with array and hash parts is not an array",
						Function = function()
							local table = {1, 2, 3, a = "hello", b = "world"}
							local result = ExtendedTableLibrary.isArray(table)
							assert(result == false, "Mixed table should not be an array")
						end,
					},
					{
						Name = "Table with negative indices is not an array",
						Function = function()
							local table = {[-1] = "negative", [1] = "positive"}
							local result = ExtendedTableLibrary.isArray(table)
							assert(result == false, "Table with negative indices should not be an array")
						end,
					},
					{
						Name = "Table with zero index is not an array",
						Function = function()
							local table = {[0] = "zero", [1] = "one", [2] = "two"}
							local result = ExtendedTableLibrary.isArray(table)
							assert(result == false, "Table with zero index should not be an array")
						end,
					},
					{
						Name = "Table with fractional indices is not an array",
						Function = function()
							local table = {[1.5] = "one-half", [2.5] = "two-half", [3.5] = "three-half"}
							local result = ExtendedTableLibrary.isArray(table)
							assert(result == false, "Table with fractional indices should not be an array")
						end,
					},
					{
						Name = "Table with boolean keys is not an array",
						Function = function()
							local table = {[true] = "yes", [false] = "no"}
							local result = ExtendedTableLibrary.isArray(table)
							assert(result == false, "Table with boolean keys should not be an array")
						end,
					},
					{
						Name = "Table with table keys is not an array",
						Function = function()
							local key1, key2 = {}, {}
							local table = {[key1] = "first", [key2] = "second"}
							local result = ExtendedTableLibrary.isArray(table)
							assert(result == false, "Table with table keys should not be an array")
						end,
					},
					{
						Name = "Array with nil values in middle",
						Function = function()
							local array = {1, 2, nil, 4, 5}
							local result = ExtendedTableLibrary.isArray(array)
							assert(result == true, "Array with nil values should still be an array (based on existing keys)")
						end,
					},
					{
						Name = "Array created with table.create",
						Function = function()
							local array = table.create(5, "default")
							local result = ExtendedTableLibrary.isArray(array)
							assert(result == true, "Array created with table.create should be an array")
						end,
					},
					{
						Name = "Array with very large indices",
						Function = function()
							local array = {[1000000] = "million"}
							local result = ExtendedTableLibrary.isArray(array)
							assert(result == true, "Array with very large positive integer indices should be an array")
						end,
					},
				},
			},

			-- isEmpty tests
			{
				Name = "isEmpty",
				TestCases = {
					{
						Name = "Empty table is empty",
						Function = function()
							local table = {}
							local result = ExtendedTableLibrary.isEmpty(table)
							assert(result == true, "Empty table should be empty")
						end,
					},
					{
						Name = "Table with array elements is not empty",
						Function = function()
							local table = {1, 2, 3}
							local result = ExtendedTableLibrary.isEmpty(table)
							assert(result == false, "Table with array elements should not be empty")
						end,
					},
					{
						Name = "Table with hash elements is not empty",
						Function = function()
							local table = {a = 1, b = 2}
							local result = ExtendedTableLibrary.isEmpty(table)
							assert(result == false, "Table with hash elements should not be empty")
						end,
					},
					{
						Name = "Table with mixed elements is not empty",
						Function = function()
							local table = {1, 2, a = "hello", b = "world"}
							local result = ExtendedTableLibrary.isEmpty(table)
							assert(result == false, "Table with mixed elements should not be empty")
						end,
					},
					{
						Name = "Table with single element is not empty",
						Function = function()
							local table = {42}
							local result = ExtendedTableLibrary.isEmpty(table)
							assert(result == false, "Table with single element should not be empty")
						end,
					},
					{
						Name = "Table with nil values only is empty",
						Function = function()
							local table = {}
							table[1] = nil
							table["key"] = nil
							local result = ExtendedTableLibrary.isEmpty(table)
							assert(result == true, "Table with only nil values should be empty")
						end,
					},
					{
						Name = "Table with false and 0 values is not empty",
						Function = function()
							local table = {false, 0, [0] = "zero"}
							local result = ExtendedTableLibrary.isEmpty(table)
							assert(result == false, "Table with false and 0 values should not be empty")
						end,
					},
				},
			},

			-- hasKey tests
			{
				Name = "hasKey",
				TestCases = {
					{
						Name = "Has existing string key",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.hasKey(table, "b")
							assert(result == true, "Should find existing string key")
						end,
					},
					{
						Name = "Does not have non-existing string key",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.hasKey(table, "d")
							assert(result == false, "Should not find non-existing string key")
						end,
					},
					{
						Name = "Has existing numeric key",
						Function = function()
							local table = {10, 20, 30, [5] = 50}
							local result = ExtendedTableLibrary.hasKey(table, 2)
							assert(result == true, "Should find existing numeric key")
						end,
					},
					{
						Name = "Has non-sequential numeric key",
						Function = function()
							local table = {10, 20, 30, [5] = 50}
							local result = ExtendedTableLibrary.hasKey(table, 5)
							assert(result == true, "Should find non-sequential numeric key")
						end,
					},
					{
						Name = "Does not have non-existing numeric key",
						Function = function()
							local table = {10, 20, 30}
							local result = ExtendedTableLibrary.hasKey(table, 5)
							assert(result == false, "Should not find non-existing numeric key")
						end,
					},
					{
						Name = "Has boolean key",
						Function = function()
							local table = {[true] = "yes", [false] = "no"}
							local result = ExtendedTableLibrary.hasKey(table, true)
							assert(result == true, "Should find boolean key")
						end,
					},
					{
						Name = "Has table as key",
						Function = function()
							local keyTable = {}
							local table = {[keyTable] = "value"}
							local result = ExtendedTableLibrary.hasKey(table, keyTable)
							assert(result == true, "Should find table key")
						end,
					},
					{
						Name = "Empty table has no keys",
						Function = function()
							local table = {}
							local result = ExtendedTableLibrary.hasKey(table, "anything")
							assert(result == false, "Empty table should not have any keys")
						end,
					},
					{
						Name = "Key with nil value still exists",
						Function = function()
							local table = {a = 1, b = nil}
							table.b = nil -- Explicitly set to nil
							table.c = "test"
							table.c = nil -- Set and then remove
							local result = ExtendedTableLibrary.hasKey(table, "b")
							assert(result == false, "Key with nil value should not exist")
						end,
					},
					{
						Name = "Mixed key types in same table",
						Function = function()
							local table = {
								[1] = "number key",
								["string"] = "string key",
								[true] = "boolean key"
							}
							assert(ExtendedTableLibrary.hasKey(table, 1) == true, "Should find number key")
							assert(ExtendedTableLibrary.hasKey(table, "string") == true, "Should find string key")
							assert(ExtendedTableLibrary.hasKey(table, true) == true, "Should find boolean key")
							assert(ExtendedTableLibrary.hasKey(table, false) == false, "Should not find non-existing boolean key")
						end,
					},
				},
			},

			-- hasValue tests
			{
				Name = "hasValue",
				TestCases = {
					{
						Name = "Has existing string value",
						Function = function()
							local table = {a = "hello", b = "world", c = "test"}
							local result = ExtendedTableLibrary.hasValue(table, "world")
							assert(result == true, "Should find existing string value")
						end,
					},
					{
						Name = "Does not have non-existing string value",
						Function = function()
							local table = {a = "hello", b = "world", c = "test"}
							local result = ExtendedTableLibrary.hasValue(table, "missing")
							assert(result == false, "Should not find non-existing string value")
						end,
					},
					{
						Name = "Has existing numeric value",
						Function = function()
							local table = {a = 10, b = 20, c = 30}
							local result = ExtendedTableLibrary.hasValue(table, 20)
							assert(result == true, "Should find existing numeric value")
						end,
					},
					{
						Name = "Has boolean value",
						Function = function()
							local table = {a = true, b = false, c = "test"}
							local result = ExtendedTableLibrary.hasValue(table, false)
							assert(result == true, "Should find boolean value")
						end,
					},
					{
						Name = "Has nil value",
						Function = function()
							local table = {a = 1, b = nil, c = 3}
							local result = ExtendedTableLibrary.hasValue(table, nil)
							assert(result == false, "Should not find nil value (nil values don't exist in tables)")
						end,
					},
					{
						Name = "Has zero value",
						Function = function()
							local table = {a = 0, b = 1, c = 2}
							local result = ExtendedTableLibrary.hasValue(table, 0)
							assert(result == true, "Should find zero value")
						end,
					},
					{
						Name = "Has table as value",
						Function = function()
							local valueTable = {x = 1}
							local table = {a = valueTable, b = "test"}
							local result = ExtendedTableLibrary.hasValue(table, valueTable)
							assert(result == true, "Should find table value")
						end,
					},
					{
						Name = "Empty table has no values",
						Function = function()
							local table = {}
							local result = ExtendedTableLibrary.hasValue(table, "anything")
							assert(result == false, "Empty table should not have any values")
						end,
					},
					{
						Name = "Array values",
						Function = function()
							local table = {"apple", "banana", "cherry"}
							assert(ExtendedTableLibrary.hasValue(table, "banana") == true, "Should find array value")
							assert(ExtendedTableLibrary.hasValue(table, "grape") == false, "Should not find non-existing array value")
						end,
					},
					{
						Name = "Duplicate values",
						Function = function()
							local table = {a = "test", b = "test", c = "other"}
							local result = ExtendedTableLibrary.hasValue(table, "test")
							assert(result == true, "Should find duplicate value")
						end,
					},
					{
						Name = "Mixed value types",
						Function = function()
							local table = {
								a = 42,
								b = "hello",
								c = true,
								d = {}
							}
							assert(ExtendedTableLibrary.hasValue(table, 42) == true, "Should find number value")
							assert(ExtendedTableLibrary.hasValue(table, "hello") == true, "Should find string value")
							assert(ExtendedTableLibrary.hasValue(table, true) == true, "Should find boolean value")
							assert(ExtendedTableLibrary.hasValue(table, table.d) == true, "Should find table value")
						end,
					},
				},
			},

			-- countOccurences tests
			{
				Name = "countOccurences",
				TestCases = {
					{
						Name = "Count single occurrence",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.countOccurences(table, 2)
							assert(result == 1, "Should count single occurrence")
						end,
					},
					{
						Name = "Count multiple occurrences",
						Function = function()
							local table = {a = "test", b = "test", c = "other", d = "test"}
							local result = ExtendedTableLibrary.countOccurences(table, "test")
							assert(result == 3, "Should count multiple occurrences")
						end,
					},
					{
						Name = "Count zero occurrences",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.countOccurences(table, 5)
							assert(result == 0, "Should count zero occurrences for non-existing value")
						end,
					},
					{
						Name = "Count boolean values",
						Function = function()
							local table = {a = true, b = false, c = true, d = true, e = false}
							local trueCount = ExtendedTableLibrary.countOccurences(table, true)
							local falseCount = ExtendedTableLibrary.countOccurences(table, false)
							assert(trueCount == 3, "Should count true occurrences correctly")
							assert(falseCount == 2, "Should count false occurrences correctly")
						end,
					},
					{
						Name = "Count zero values",
						Function = function()
							local table = {a = 0, b = 1, c = 0, d = 2, e = 0}
							local result = ExtendedTableLibrary.countOccurences(table, 0)
							assert(result == 3, "Should count zero values correctly")
						end,
					},
					{
						Name = "Count in array",
						Function = function()
							local table = {1, 2, 2, 3, 2, 4, 2}
							local result = ExtendedTableLibrary.countOccurences(table, 2)
							assert(result == 4, "Should count occurrences in array")
						end,
					},
					{
						Name = "Count in empty table",
						Function = function()
							local table = {}
							local result = ExtendedTableLibrary.countOccurences(table, "anything")
							assert(result == 0, "Should count zero in empty table")
						end,
					},
					{
						Name = "Count table values",
						Function = function()
							local sharedTable = {x = 1}
							local anotherTable = {y = 2}
							local table = {a = sharedTable, b = anotherTable, c = sharedTable}
							local result = ExtendedTableLibrary.countOccurences(table, sharedTable)
							assert(result == 2, "Should count table value occurrences")
						end,
					},
					{
						Name = "Count nil values",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.countOccurences(table, nil)
							assert(result == 0, "Should count zero nil values (nil values don't exist in tables)")
						end,
					},
					{
						Name = "Count in mixed table",
						Function = function()
							local table = {1, 2, "test", a = "test", b = 2, c = "test"}
							local testCount = ExtendedTableLibrary.countOccurences(table, "test")
							local twoCount = ExtendedTableLibrary.countOccurences(table, 2)
							assert(testCount == 3, "Should count string occurrences in mixed table")
							assert(twoCount == 2, "Should count number occurrences in mixed table")
						end,
					},
				},
			},

			-- countKeysByType tests
			{
				Name = "countKeysByType",
				TestCases = {
					{
						Name = "Count string keys",
						Function = function()
							local table = {a = 1, b = 2, c = 3, [1] = "one", [2] = "two"}
							local result = ExtendedTableLibrary.countKeysByType(table, "string")
							assert(result == 3, "Should count string keys correctly")
						end,
					},
					{
						Name = "Count number keys",
						Function = function()
							local table = {a = 1, b = 2, [1] = "one", [2] = "two", [3] = "three"}
							local result = ExtendedTableLibrary.countKeysByType(table, "number")
							assert(result == 3, "Should count number keys correctly")
						end,
					},
					{
						Name = "Count boolean keys",
						Function = function()
							local table = {[true] = "yes", [false] = "no", a = 1, [1] = "one"}
							local result = ExtendedTableLibrary.countKeysByType(table, "boolean")
							assert(result == 2, "Should count boolean keys correctly")
						end,
					},
					{
						Name = "Count table keys",
						Function = function()
							local key1, key2 = {}, {}
							local table = {[key1] = "first", [key2] = "second", a = 1, [1] = "one"}
							local result = ExtendedTableLibrary.countKeysByType(table, "table")
							assert(result == 2, "Should count table keys correctly")
						end,
					},
					{
						Name = "Count non-existing key type",
						Function = function()
							local table = {a = 1, b = 2, [1] = "one", [2] = "two"}
							local result = ExtendedTableLibrary.countKeysByType(table, "function")
							assert(result == 0, "Should count zero for non-existing key type")
						end,
					},
					{
						Name = "Count keys in empty table",
						Function = function()
							local table = {}
							local result = ExtendedTableLibrary.countKeysByType(table, "string")
							assert(result == 0, "Should count zero keys in empty table")
						end,
					},
					{
						Name = "Count keys in array-only table",
						Function = function()
							local table = {1, 2, 3, 4, 5}
							local result = ExtendedTableLibrary.countKeysByType(table, "number")
							assert(result == 5, "Should count all array indices as number keys")
						end,
					},
					{
						Name = "Count keys in hash-only table",
						Function = function()
							local table = {a = 1, b = 2, c = 3, d = 4}
							local result = ExtendedTableLibrary.countKeysByType(table, "string")
							assert(result == 4, "Should count all hash keys as string keys")
						end,
					},
					{
						Name = "Count mixed key types in single table",
						Function = function()
							local obj = {}
							local table = {
								a = 1,                    -- string key
								[1] = "one",              -- number key
								[true] = "yes",           -- boolean key
								[obj] = "object"          -- table key
							}
							assert(ExtendedTableLibrary.countKeysByType(table, "string") == 1, "Should count 1 string key")
							assert(ExtendedTableLibrary.countKeysByType(table, "number") == 1, "Should count 1 number key")
							assert(ExtendedTableLibrary.countKeysByType(table, "boolean") == 1, "Should count 1 boolean key")
							assert(ExtendedTableLibrary.countKeysByType(table, "table") == 1, "Should count 1 table key")
						end,
					},
					{
						Name = "Count with case sensitivity",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.countKeysByType(table, "String")
							assert(result == 0, "Should be case sensitive - 'String' vs 'string'")
						end,
					},
				},
			},

			-- countValuesByType tests
			{
				Name = "countValuesByType",
				TestCases = {
					{
						Name = "Count string values",
						Function = function()
							local table = {a = "hello", b = "world", c = 123, d = "test"}
							local result = ExtendedTableLibrary.countValuesByType(table, "string")
							assert(result == 3, "Should count string values correctly")
						end,
					},
					{
						Name = "Count number values",
						Function = function()
							local table = {a = 1, b = "hello", c = 2.5, d = "world", e = 0}
							local result = ExtendedTableLibrary.countValuesByType(table, "number")
							assert(result == 3, "Should count number values correctly")
						end,
					},
					{
						Name = "Count boolean values",
						Function = function()
							local table = {a = true, b = "hello", c = false, d = 123, e = true}
							local result = ExtendedTableLibrary.countValuesByType(table, "boolean")
							assert(result == 3, "Should count boolean values correctly")
						end,
					},
					{
						Name = "Count table values",
						Function = function()
							local table = {a = {x = 1}, b = "hello", c = {y = 2}, d = 123}
							local result = ExtendedTableLibrary.countValuesByType(table, "table")
							assert(result == 2, "Should count table values correctly")
						end,
					},
					{
						Name = "Count function values",
						Function = function()
							local func1 = function() end
							local func2 = function() end
							local table = {a = func1, b = "hello", c = func2, d = 123}
							local result = ExtendedTableLibrary.countValuesByType(table, "function")
							assert(result == 2, "Should count function values correctly")
						end,
					},
					{
						Name = "Count non-existing value type",
						Function = function()
							local table = {a = "hello", b = 123, c = true}
							local result = ExtendedTableLibrary.countValuesByType(table, "thread")
							assert(result == 0, "Should count zero for non-existing value type")
						end,
					},
					{
						Name = "Count values in empty table",
						Function = function()
							local table = {}
							local result = ExtendedTableLibrary.countValuesByType(table, "string")
							assert(result == 0, "Should count zero values in empty table")
						end,
					},
					{
						Name = "Count values in array",
						Function = function()
							local table = {"hello", "world", 123, "test", true}
							local stringCount = ExtendedTableLibrary.countValuesByType(table, "string")
							local numberCount = ExtendedTableLibrary.countValuesByType(table, "number")
							local booleanCount = ExtendedTableLibrary.countValuesByType(table, "boolean")
							assert(stringCount == 3, "Should count 3 string values in array")
							assert(numberCount == 1, "Should count 1 number value in array")
							assert(booleanCount == 1, "Should count 1 boolean value in array")
						end,
					},
					{
						Name = "Count all same type values",
						Function = function()
							local table = {a = "one", b = "two", c = "three", d = "four"}
							local result = ExtendedTableLibrary.countValuesByType(table, "string")
							assert(result == 4, "Should count all values when they are the same type")
						end,
					},
					{
						Name = "Count with mixed value types",
						Function = function()
							local table = {
								a = "string",
								b = 42,
								c = true,
								d = {},
								e = function() end
							}
							assert(ExtendedTableLibrary.countValuesByType(table, "string") == 1, "Should count 1 string value")
							assert(ExtendedTableLibrary.countValuesByType(table, "number") == 1, "Should count 1 number value")
							assert(ExtendedTableLibrary.countValuesByType(table, "boolean") == 1, "Should count 1 boolean value")
							assert(ExtendedTableLibrary.countValuesByType(table, "table") == 1, "Should count 1 table value")
							assert(ExtendedTableLibrary.countValuesByType(table, "function") == 1, "Should count 1 function value")
						end,
					},
					{
						Name = "Count with special number values",
						Function = function()
							local table = {a = 0, b = -1, c = 3.14, d = math.huge, e = -math.huge}
							local result = ExtendedTableLibrary.countValuesByType(table, "number")
							assert(result == 5, "Should count all number values including 0, negative, float, and infinity")
						end,
					},
					{
						Name = "Count with case sensitivity",
						Function = function()
							local table = {a = "hello", b = "world", c = 123}
							local result = ExtendedTableLibrary.countValuesByType(table, "String")
							assert(result == 0, "Should be case sensitive - 'String' vs 'string'")
						end,
					},
				},
			},

			-- keysOfValue tests
			{
				Name = "keysOfValue",
				TestCases = {
					{
						Name = "Find keys for existing value",
						Function = function()
							local table = {a = 1, b = 2, c = 1, d = 3}
							local result = ExtendedTableLibrary.keysOfValue(table, 1)

							-- Sort for consistent comparison
							ExtendedTableLibrary.sort(result)
							assert(deepEqual(result, {"a", "c"}), "Should find all keys for value 1")
						end,
					},
					{
						Name = "Find keys for non-existing value",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.keysOfValue(table, 5)
							assert(deepEqual(result, {}), "Should return empty array for non-existing value")
						end,
					},
					{
						Name = "Find keys for unique value",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.keysOfValue(table, 2)
							assert(deepEqual(result, {"b"}), "Should find single key for unique value")
						end,
					},
					{
						Name = "Find keys in array",
						Function = function()
							local table = {"apple", "banana", "apple", "cherry", "apple"}
							local result = ExtendedTableLibrary.keysOfValue(table, "apple")

							-- Sort for consistent comparison
							ExtendedTableLibrary.sort(result)
							assert(deepEqual(result, {1, 3, 5}), "Should find all array indices for value")
						end,
					},
					{
						Name = "Find keys for string value",
						Function = function()
							local table = {a = "test", b = "hello", c = "test", d = "world"}
							local result = ExtendedTableLibrary.keysOfValue(table, "test")

							-- Sort for consistent comparison
							ExtendedTableLibrary.sort(result)
							assert(deepEqual(result, {"a", "c"}), "Should find all keys for string value")
						end,
					},
					{
						Name = "Find keys for boolean value",
						Function = function()
							local table = {a = true, b = false, c = true, d = 1, e = false}
							local trueKeys = ExtendedTableLibrary.keysOfValue(table, true)
							local falseKeys = ExtendedTableLibrary.keysOfValue(table, false)

							-- Sort for consistent comparison
							ExtendedTableLibrary.sort(trueKeys)
							ExtendedTableLibrary.sort(falseKeys)

							assert(deepEqual(trueKeys, {"a", "c"}), "Should find all keys for true value")
							assert(deepEqual(falseKeys, {"b", "e"}), "Should find all keys for false value")
						end,
					},
					{
						Name = "Find keys for table value",
						Function = function()
							local sharedTable = {x = 1}
							local table = {a = sharedTable, b = {y = 2}, c = sharedTable}
							local result = ExtendedTableLibrary.keysOfValue(table, sharedTable)

							-- Sort for consistent comparison
							ExtendedTableLibrary.sort(result)
							assert(deepEqual(result, {"a", "c"}), "Should find all keys for table value")
						end,
					},
					{
						Name = "Find keys in empty table",
						Function = function()
							local table = {}
							local result = ExtendedTableLibrary.keysOfValue(table, "anything")
							assert(deepEqual(result, {}), "Should return empty array for empty table")
						end,
					},
					{
						Name = "Find keys for zero value",
						Function = function()
							local table = {a = 0, b = 1, c = 0, d = false}
							local result = ExtendedTableLibrary.keysOfValue(table, 0)

							-- Sort for consistent comparison
							ExtendedTableLibrary.sort(result)
							assert(deepEqual(result, {"a", "c"}), "Should find keys for zero value (not false)")
						end,
					},
					{
						Name = "Find keys with mixed key types",
						Function = function()
							local table = {
								a = "test",           -- string key
								[1] = "test",         -- number key
								[true] = "test",      -- boolean key
							}
							local result = ExtendedTableLibrary.keysOfValue(table, "test")

							-- Sort with custom comparator for mixed types
							ExtendedTableLibrary.sort(result, function(a, b)
								if type(a) == type(b) then
									return a < b
								else
									return type(a) < type(b)
								end
							end)

							assert(deepEqual(result, {true, 1, "a"}), "Should find all keys regardless of key type")
						end,
					},
					{
						Name = "Find keys for nil value",
						Function = function()
							local table = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.keysOfValue(table, nil)
							assert(deepEqual(result, {}), "Should return empty array for nil value")
						end,
					},
					{
						Name = "Find keys preserves key types",
						Function = function()
							local table = {
								[1] = "found",
								[2.5] = "found",
								["string"] = "found",
								[true] = "found"
							}
							local result = ExtendedTableLibrary.keysOfValue(table, "found")

							-- Check that we have the right number of keys
							assert(#result == 4, "Should find 4 keys")

							-- Check that original key types are preserved
							local hasNumber, hasFloat, hasString, hasBoolean = false, false, false, false
							for _, key in result do
								if key == 1 then hasNumber = true
								elseif key == 2.5 then hasFloat = true
								elseif key == "string" then hasString = true
								elseif key == true then hasBoolean = true
								end
							end

							assert(hasNumber and hasFloat and hasString and hasBoolean, "Should preserve all key types")
						end,
					},
				},
			},
		}
	},

	[5] = {
		Name = "Functional Utilities",

		TestCases = {
			-- deepCopy tests
			{
				Name = "deepCopy",
				TestCases = {
					{
						Name = "Deep copy simple table",
						Function = function()
							local original = {a = 1, b = 2, c = 3}
							local copy = ExtendedTableLibrary.deepCopy(original)

							assert(deepEqual(copy, original), "Copy should be equal to original")
							assert(copy ~= original, "Copy should be a different table reference")

							-- Modify copy to ensure independence
							copy.a = 999
							assert(original.a == 1, "Original should remain unchanged when copy is modified")
						end,
					},
					{
						Name = "Deep copy nested table",
						Function = function()
							local original = {
								a = 1,
								b = {
									x = 10,
									y = {
										z = 100
									}
								},
								c = 3
							}
							local copy = ExtendedTableLibrary.deepCopy(original)

							assert(deepEqual(copy, original), "Copy should be equal to original")
							assert(copy ~= original, "Copy should be a different table reference")
							assert(copy.b ~= original.b, "Nested table should be a different reference")
							assert(copy.b.y ~= original.b.y, "Deeply nested table should be a different reference")

							-- Modify nested values to ensure independence
							copy.b.x = 999
							copy.b.y.z = 999
							assert(original.b.x == 10, "Original nested value should remain unchanged")
							assert(original.b.y.z == 100, "Original deeply nested value should remain unchanged")
						end,
					},
					{
						Name = "Deep copy array",
						Function = function()
							local original = {1, 2, {3, 4, {5, 6}}}
							local copy = ExtendedTableLibrary.deepCopy(original)

							assert(deepEqual(copy, original), "Array copy should be equal to original")
							assert(copy ~= original, "Array copy should be a different reference")
							assert(copy[3] ~= original[3], "Nested array should be a different reference")
							assert(copy[3][3] ~= original[3][3], "Deeply nested array should be a different reference")

							-- Modify nested array to ensure independence
							copy[3][1] = 999
							copy[3][3][1] = 999
							assert(original[3][1] == 3, "Original nested array should remain unchanged")
							assert(original[3][3][1] == 5, "Original deeply nested array should remain unchanged")
						end,
					},
					{
						Name = "Deep copy empty table",
						Function = function()
							local original = {}
							local copy = ExtendedTableLibrary.deepCopy(original)

							assert(deepEqual(copy, original), "Empty table copy should be equal to original")
							assert(copy ~= original, "Empty table copy should be a different reference")
						end,
					},
					{
						Name = "Deep copy table with mixed key types",
						Function = function()
							local original = {
								[1] = "number key",
								["string"] = "string key",
								[true] = "boolean key",
								nested = {
									[2] = "nested number",
									["nested_string"] = "nested string"
								}
							}
							local copy = ExtendedTableLibrary.deepCopy(original)

							assert(deepEqual(copy, original), "Mixed key table copy should be equal to original")
							assert(copy ~= original, "Copy should be a different reference")
							assert(copy.nested ~= original.nested, "Nested table should be a different reference")

							-- Verify all key types are preserved
							assert(copy[1] == "number key", "Number key should be preserved")
							assert(copy["string"] == "string key", "String key should be preserved")
							assert(copy[true] == "boolean key", "Boolean key should be preserved")
						end,
					},
					{
						Name = "Deep copy table with circular reference",
						Function = function()
							local original = {a = 1, b = 2}
							original.self = original -- Create circular reference

							local copy = ExtendedTableLibrary.deepCopy(original)

							assert(copy.a == 1, "Simple values should be copied")
							assert(copy.b == 2, "Simple values should be copied")
							assert(copy.self == copy, "Circular reference should point to copy, not original")
							assert(copy ~= original, "Copy should be different from original")
						end,
					},
					{
						Name = "Deep copy table with multiple references to same subtable",
						Function = function()
							local shared = {x = 10, y = 20}
							local original = {
								a = shared,
								b = shared,
								c = {nested = shared}
							}

							local copy = ExtendedTableLibrary.deepCopy(original)

							assert(copy.a == copy.b, "Multiple references should point to same copy")
							assert(copy.a == copy.c.nested, "All references should point to same copy")
							assert(copy.a ~= original.a, "Copy should be different from original")

							-- Modify shared reference to ensure proper copying
							copy.a.x = 999
							assert(copy.b.x == 999, "All references in copy should reflect changes")
							assert(copy.c.nested.x == 999, "All references in copy should reflect changes")
							assert(original.a.x == 10, "Original should remain unchanged")
						end,
					},
					{
						Name = "Deep copy with special values",
						Function = function()
							local func = function() return "test" end
							local thread = coroutine.create(function() end)
							local original = {
								num = 42,
								str = "hello",
								bool = true,
								func = func,
								thread = thread,
								nan = 0/0,
								inf = math.huge,
								negInf = -math.huge
							}

							local copy = ExtendedTableLibrary.deepCopy(original)

							assert(copy.num == 42, "Number should be copied")
							assert(copy.str == "hello", "String should be copied")
							assert(copy.bool == true, "Boolean should be copied")
							assert(copy.func == func, "Function should be same reference")
							assert(copy.thread == thread, "Thread should be same reference")
							assert(copy.nan ~= copy.nan, "NaN should be copied as NaN")
							assert(copy.inf == math.huge, "Infinity should be copied")
							assert(copy.negInf == -math.huge, "Negative infinity should be copied")
						end,
					},
					{
						Name = "Deep copy preserves metatable",
						Function = function()
							local mt = {__index = function() return "default" end}
							local original = setmetatable({a = 1}, mt)
							local copy = ExtendedTableLibrary.deepCopy(original)

							assert(copy.a == 1, "Value should be copied")
							assert(getmetatable(copy) == mt, "Metatable should be preserved")
							assert(copy.nonexistent == "default", "Metatable should function correctly")
						end,
					},
				},
			},

			-- deepEqual tests
			{
				Name = "deepEqual",
				TestCases = {
					{
						Name = "Equal primitive values",
						Function = function()
							assert(ExtendedTableLibrary.deepEqual(1, 1) == true, "Equal numbers should be equal")
							assert(ExtendedTableLibrary.deepEqual("hello", "hello") == true, "Equal strings should be equal")
							assert(ExtendedTableLibrary.deepEqual(true, true) == true, "Equal booleans should be equal")
							assert(ExtendedTableLibrary.deepEqual(nil, nil) == true, "nil values should be equal")
						end,
					},
					{
						Name = "Different primitive values",
						Function = function()
							assert(ExtendedTableLibrary.deepEqual(1, 2) == false, "Different numbers should not be equal")
							assert(ExtendedTableLibrary.deepEqual("hello", "world") == false, "Different strings should not be equal")
							assert(ExtendedTableLibrary.deepEqual(true, false) == false, "Different booleans should not be equal")
							assert(ExtendedTableLibrary.deepEqual(1, "1") == false, "Different types should not be equal")
							assert(ExtendedTableLibrary.deepEqual(nil, 0) == false, "nil and 0 should not be equal")
							assert(ExtendedTableLibrary.deepEqual(false, nil) == false, "false and nil should not be equal")
						end,
					},
					{
						Name = "Equal simple tables",
						Function = function()
							local a = {x = 1, y = 2, z = 3}
							local b = {x = 1, y = 2, z = 3}
							assert(ExtendedTableLibrary.deepEqual(a, b) == true, "Tables with same content should be equal")
						end,
					},
					{
						Name = "Different simple tables",
						Function = function()
							local a = {x = 1, y = 2, z = 3}
							local b = {x = 1, y = 2, z = 4}
							assert(ExtendedTableLibrary.deepEqual(a, b) == false, "Tables with different values should not be equal")
						end,
					},
					{
						Name = "Tables with different keys",
						Function = function()
							local a = {x = 1, y = 2}
							local b = {x = 1, z = 2}
							assert(ExtendedTableLibrary.deepEqual(a, b) == false, "Tables with different keys should not be equal")
						end,
					},
					{
						Name = "Tables with different number of keys",
						Function = function()
							local a = {x = 1, y = 2}
							local b = {x = 1, y = 2, z = 3}
							assert(ExtendedTableLibrary.deepEqual(a, b) == false, "Tables with different number of keys should not be equal")
						end,
					},
					{
						Name = "Equal nested tables",
						Function = function()
							local a = {
								x = 1,
								y = {
									a = 10,
									b = {
										nested = "deep"
									}
								}
							}
							local b = {
								x = 1,
								y = {
									a = 10,
									b = {
										nested = "deep"
									}
								}
							}
							assert(ExtendedTableLibrary.deepEqual(a, b) == true, "Nested tables with same structure should be equal")
						end,
					},
					{
						Name = "Different nested tables",
						Function = function()
							local a = {
								x = 1,
								y = {
									a = 10,
									b = {
										nested = "deep"
									}
								}
							}
							local b = {
								x = 1,
								y = {
									a = 10,
									b = {
										nested = "different"
									}
								}
							}
							assert(ExtendedTableLibrary.deepEqual(a, b) == false, "Nested tables with different values should not be equal")
						end,
					},
					{
						Name = "Equal arrays",
						Function = function()
							local a = {1, 2, 3, {4, 5, {6, 7}}}
							local b = {1, 2, 3, {4, 5, {6, 7}}}
							assert(ExtendedTableLibrary.deepEqual(a, b) == true, "Arrays with same content should be equal")
						end,
					},
					{
						Name = "Different arrays",
						Function = function()
							local a = {1, 2, 3, {4, 5, {6, 7}}}
							local b = {1, 2, 3, {4, 5, {6, 8}}}
							assert(ExtendedTableLibrary.deepEqual(a, b) == false, "Arrays with different content should not be equal")
						end,
					},
					{
						Name = "Arrays with different lengths",
						Function = function()
							local a = {1, 2, 3}
							local b = {1, 2, 3, 4}
							assert(ExtendedTableLibrary.deepEqual(a, b) == false, "Arrays with different lengths should not be equal")
						end,
					},
					{
						Name = "Empty tables",
						Function = function()
							local a = {}
							local b = {}
							assert(ExtendedTableLibrary.deepEqual(a, b) == true, "Empty tables should be equal")
						end,
					},
					{
						Name = "Table vs non-table",
						Function = function()
							local a = {x = 1}
							local b = "not a table"
							assert(ExtendedTableLibrary.deepEqual(a, b) == false, "Table and non-table should not be equal")
						end,
					},
					{
						Name = "Same table reference",
						Function = function()
							local a = {x = 1, y = 2}
							assert(ExtendedTableLibrary.deepEqual(a, a) == true, "Same table reference should be equal to itself")
						end,
					},
					{
						Name = "Tables with mixed key types",
						Function = function()
							local keyTable = {}
							local a = {
								[1] = "one",
								["string"] = "value",
								[true] = "boolean",
								[keyTable] = "table key"
							}
							local b = {
								[1] = "one",
								["string"] = "value",
								[true] = "boolean",
								[keyTable] = "table key"
							}
							assert(ExtendedTableLibrary.deepEqual(a, b) == true, "Tables with same mixed keys should be equal")
						end,
					},
					{
						Name = "Circular references - same structure",
						Function = function()
							local a = {x = 1}
							a.self = a
							local b = {x = 1}
							b.self = b
							assert(ExtendedTableLibrary.deepEqual(a, b) == true, "Tables with same circular structure should be equal")
						end,
					},
					{
						Name = "Circular references - different structure",
						Function = function()
							local a = {x = 1}
							a.self = a
							local b = {x = 2}
							b.self = b
							assert(ExtendedTableLibrary.deepEqual(a, b) == false, "Tables with different values but same circular structure should not be equal")
						end,
					},
					{
						Name = "Shared subtables",
						Function = function()
							local shared1 = {data = "shared"}
							local shared2 = {data = "shared"}
							local a = {ref1 = shared1, ref2 = shared1}
							local b = {ref1 = shared2, ref2 = shared2}
							assert(ExtendedTableLibrary.deepEqual(a, b) == true, "Tables with equivalent shared subtables should be equal")
						end,
					},
					{
						Name = "Special numeric values",
						Function = function()
							local a = {nan = 0/0, inf = math.huge, negInf = -math.huge}
							local b = {nan = 0/0, inf = math.huge, negInf = -math.huge}
							assert(ExtendedTableLibrary.deepEqual(a, b) == true, "Tables with special numeric values should be equal")
						end,
					},
					{
						Name = "Functions and threads",
						Function = function()
							local func = function() return "test" end
							local thread = coroutine.create(function() end)
							local a = {f = func, t = thread}
							local b = {f = func, t = thread}
							assert(ExtendedTableLibrary.deepEqual(a, b) == true, "Tables with same function/thread references should be equal")

							local differentFunc = function() return "test" end
							local c = {f = differentFunc, t = thread}
							assert(ExtendedTableLibrary.deepEqual(a, c) == false, "Tables with different function references should not be equal")
						end,
					},
				},
			},

			-- deepFreeze tests
			{
				Name = "deepFreeze",
				TestCases = {
					{
						Name = "Freeze simple table completely",
						Function = function()
							local tbl = {a = 1, b = 2, c = 3}
							local frozen = ExtendedTableLibrary.deepFreeze(tbl)

							assert(frozen == tbl, "Should return the same table reference")

							-- Test that table is frozen
							local success = pcall(function()
								tbl.a = 999
							end)
							assert(not success, "Should not be able to modify frozen table")

							success = pcall(function()
								tbl.d = "new"
							end)
							assert(not success, "Should not be able to add to frozen table")
						end,
					},
					{
						Name = "Freeze nested table completely",
						Function = function()
							local tbl = {
								a = 1,
								b = {
									x = 10,
									y = {
										z = 100
									}
								}
							}
							ExtendedTableLibrary.deepFreeze(tbl)

							-- Test that main table is frozen
							local success = pcall(function()
								tbl.a = 999
							end)
							assert(not success, "Main table should be frozen")

							-- Test that nested table is frozen
							success = pcall(function()
								tbl.b.x = 999
							end)
							assert(not success, "Nested table should be frozen")

							-- Test that deeply nested table is frozen
							success = pcall(function()
								tbl.b.y.z = 999
							end)
							assert(not success, "Deeply nested table should be frozen")
						end,
					},
					{
						Name = "Freeze with depth limit 1",
						Function = function()
							local tbl = {
								a = 1,
								b = {
									x = 10,
									y = {
										z = 100
									}
								}
							}
							ExtendedTableLibrary.deepFreeze(tbl, 1)

							-- Main table should be frozen
							local success = pcall(function()
								tbl.a = 999
							end)
							assert(not success, "Main table should be frozen")

							-- First level nested table should be frozen
							success = pcall(function()
								tbl.b.x = 999
							end)
							assert(not success, "First level nested table should be frozen")

							-- Second level nested table should NOT be frozen
							success = pcall(function()
								tbl.b.y.z = 999
							end)
							assert(success, "Second level nested table should not be frozen with depth 1")
							assert(tbl.b.y.z == 999, "Value should have been modified")
						end,
					},
					{
						Name = "Freeze with depth limit 0",
						Function = function()
							local tbl = {
								a = 1,
								b = {
									x = 10,
									y = {
										z = 100
									}
								}
							}
							ExtendedTableLibrary.deepFreeze(tbl, 0)

							-- Main table should be frozen
							local success = pcall(function()
								tbl.a = 999
							end)
							assert(not success, "Main table should be frozen even with depth 0")

							-- Nested table should NOT be frozen
							success = pcall(function()
								tbl.b.x = 999
							end)
							assert(success, "Nested table should not be frozen with depth 0")
							assert(tbl.b.x == 999, "Nested value should have been modified")
						end,
					},
					{
						Name = "Freeze array",
						Function = function()
							local arr = {1, 2, {3, 4, {5, 6}}}
							ExtendedTableLibrary.deepFreeze(arr)

							-- Array should be frozen
							local success = pcall(function()
								arr[1] = 999
							end)
							assert(not success, "Array should be frozen")

							-- Nested array should be frozen
							success = pcall(function()
								arr[3][1] = 999
							end)
							assert(not success, "Nested array should be frozen")

							-- Deeply nested array should be frozen
							success = pcall(function()
								arr[3][3][1] = 999
							end)
							assert(not success, "Deeply nested array should be frozen")
						end,
					},
					{
						Name = "Freeze empty table",
						Function = function()
							local tbl = {}
							local frozen = ExtendedTableLibrary.deepFreeze(tbl)

							assert(frozen == tbl, "Should return the same table reference")

							local success = pcall(function()
								tbl.a = 1
							end)
							assert(not success, "Should not be able to add to frozen empty table")
						end,
					},
					{
						Name = "Freeze table with circular reference",
						Function = function()
							local tbl = {a = 1, b = 2}
							tbl.self = tbl

							ExtendedTableLibrary.deepFreeze(tbl)

							local success = pcall(function()
								tbl.a = 999
							end)
							assert(not success, "Table with circular reference should be frozen")

							success = pcall(function()
								tbl.self.b = 999
							end)
							assert(not success, "Circular reference should also be frozen")
						end,
					},
					{
						Name = "Freeze shared subtables",
						Function = function()
							local shared = {data = "shared"}
							local tbl = {ref1 = shared, ref2 = shared}

							ExtendedTableLibrary.deepFreeze(tbl)

							local success = pcall(function()
								tbl.ref1.data = "modified"
							end)
							assert(not success, "Shared subtable should be frozen")

							success = pcall(function()
								tbl.ref2.data = "modified"
							end)
							assert(not success, "All references to shared subtable should be frozen")
						end,
					},
					{
						Name = "Freeze preserves functionality",
						Function = function()
							local tbl = {a = 1, b = 2, c = {x = 10}}
							ExtendedTableLibrary.deepFreeze(tbl)

							-- Should still be able to read values
							assert(tbl.a == 1, "Should still be able to read values")
							assert(tbl.c.x == 10, "Should still be able to read nested values")

							-- Should still be able to iterate
							local count = 0
							for k, v in pairs(tbl) do
								count = count + 1
							end
							assert(count == 3, "Should still be able to iterate over frozen table")
						end,
					},
					{
						Name = "Freeze with mixed key types",
						Function = function()
							local keyTable = {}
							local tbl = {
								[1] = "number key",
								["string"] = "string key",
								[true] = "boolean key",
								[keyTable] = "table key",
								nested = {value = "nested"}
							}
							ExtendedTableLibrary.deepFreeze(tbl)

							-- Test all key types are protected
							local success = pcall(function()
								tbl[1] = "modified"
							end)
							assert(not success, "Number key should be protected")

							success = pcall(function()
								tbl["string"] = "modified"
							end)
							assert(not success, "String key should be protected")

							success = pcall(function()
								tbl[true] = "modified"
							end)
							assert(not success, "Boolean key should be protected")

							success = pcall(function()
								tbl[keyTable] = "modified"
							end)
							assert(not success, "Table key should be protected")

							success = pcall(function()
								tbl.nested.value = "modified"
							end)
							assert(not success, "Nested table should be protected")
						end,
					},
					{
						Name = "Freeze does not affect non-table values",
						Function = function()
							local func = function() return "test" end
							local tbl = {
								num = 42,
								str = "hello",
								bool = true,
								func = func,
								nested = {inner = "value"}
							}
							ExtendedTableLibrary.deepFreeze(tbl)

							-- Non-table values should remain accessible and unchanged
							assert(tbl.num == 42, "Number should remain accessible")
							assert(tbl.str == "hello", "String should remain accessible")
							assert(tbl.bool == true, "Boolean should remain accessible")
							assert(tbl.func() == "test", "Function should remain callable")
						end,
					},
				},
			},

			-- findMatch tests
			{
				Name = "findMatch",
				TestCases = {
					{
						Name = "Find first matching key in hash table",
						Function = function()
							local tbl = {a = 10, b = 20, c = 30, d = 40}
							local result = ExtendedTableLibrary.findMatch(tbl, function(key, value)
								return value > 25
							end)
							-- Should find either 'c' or 'd' since both have values > 25
							assert(result == "c" or result == "d", "Should find a key with value > 25")
							assert(tbl[result] > 25, "Found key should have value > 25")
						end,
					},
					{
						Name = "Find first matching key by key pattern",
						Function = function()
							local tbl = {apple = 1, banana = 2, apricot = 3, cherry = 4}
							local result = ExtendedTableLibrary.findMatch(tbl, function(key, value)
								return string.sub(key, 1, 2) == "ap"
							end)
							assert(result == "apple" or result == "apricot", "Should find key starting with 'ap'")
							assert(string.sub(result, 1, 2) == "ap", "Found key should start with 'ap'")
						end,
					},
					{
						Name = "Find in array by index",
						Function = function()
							local tbl = {"first", "second", "third", "fourth"}
							local result = ExtendedTableLibrary.findMatch(tbl, function(key, value)
								return key > 2 and string.len(value) > 5
							end)
							assert(result == 3 or result == 4, "Should find index 3 or 4")
							assert(tbl[result] and string.len(tbl[result]) > 5, "Found value should have length > 5")
						end,
					},
					{
						Name = "No match found",
						Function = function()
							local tbl = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.findMatch(tbl, function(key, value)
								return value > 10
							end)
							assert(result == nil, "Should return nil when no match is found")
						end,
					},
					{
						Name = "Empty table returns nil",
						Function = function()
							local tbl = {}
							local result = ExtendedTableLibrary.findMatch(tbl, function(key, value)
								return true
							end)
							assert(result == nil, "Should return nil for empty table")
						end,
					},
					{
						Name = "First match with multiple matches",
						Function = function()
							local tbl = {a = 5, b = 10, c = 15, d = 20}
							local result = ExtendedTableLibrary.findMatch(tbl, function(key, value)
								return value >= 10
							end)
							assert(result ~= nil, "Should find a match")
							assert(tbl[result] >= 10, "Found value should be >= 10")
							-- Note: We can't guarantee which specific key is returned first due to table iteration order
						end,
					},
					{
						Name = "Match by key type",
						Function = function()
							local tbl = {[1] = "number", ["string"] = "string", [true] = "boolean"}
							local result = ExtendedTableLibrary.findMatch(tbl, function(key, value)
								return type(key) == "boolean"
							end)
							assert(result == true, "Should find the boolean key")
						end,
					},
					{
						Name = "Match by value type",
						Function = function()
							local tbl = {a = 42, b = "hello", c = true, d = {}}
							local result = ExtendedTableLibrary.findMatch(tbl, function(key, value)
								return type(value) == "table"
							end)
							assert(result == "d", "Should find key with table value")
						end,
					},
				},
			},

			-- every tests
			{
				Name = "every",
				TestCases = {
					{
						Name = "All elements satisfy condition",
						Function = function()
							local tbl = {a = 2, b = 4, c = 6, d = 8}
							local result = ExtendedTableLibrary.every(tbl, function(key, value)
								return value % 2 == 0
							end)
							assert(result == true, "All values are even, should return true")
						end,
					},
					{
						Name = "Not all elements satisfy condition",
						Function = function()
							local tbl = {a = 2, b = 4, c = 5, d = 8}
							local result = ExtendedTableLibrary.every(tbl, function(key, value)
								return value % 2 == 0
							end)
							assert(result == false, "Not all values are even, should return false")
						end,
					},
					{
						Name = "Empty table returns true",
						Function = function()
							local tbl = {}
							local result = ExtendedTableLibrary.every(tbl, function(key, value)
								return false -- Even impossible condition should return true for empty table
							end)
							assert(result == true, "Empty table should return true (vacuous truth)")
						end,
					},
					{
						Name = "All string keys satisfy condition",
						Function = function()
							local tbl = {apple = 1, apricot = 2, avocado = 3}
							local result = ExtendedTableLibrary.every(tbl, function(key, value)
								return string.sub(key, 1, 1) == "a"
							end)
							assert(result == true, "All keys start with 'a', should return true")
						end,
					},
					{
						Name = "Array where all elements satisfy condition",
						Function = function()
							local tbl = {10, 20, 30, 40, 50}
							local result = ExtendedTableLibrary.every(tbl, function(key, value)
								return value >= 10 and key <= 5
							end)
							assert(result == true, "All values >= 10 and indices <= 5, should return true")
						end,
					},
					{
						Name = "Array where not all elements satisfy condition",
						Function = function()
							local tbl = {10, 20, 5, 40, 50}
							local result = ExtendedTableLibrary.every(tbl, function(key, value)
								return value >= 10
							end)
							assert(result == false, "Not all values >= 10, should return false")
						end,
					},
					{
						Name = "Mixed key types all satisfy condition",
						Function = function()
							local tbl = {[1] = "one", ["two"] = 2, [true] = "yes"}
							local result = ExtendedTableLibrary.every(tbl, function(key, value)
								return value ~= nil
							end)
							assert(result == true, "All values are non-nil, should return true")
						end,
					},
					{
						Name = "Single element table that satisfies",
						Function = function()
							local tbl = {a = 42}
							local result = ExtendedTableLibrary.every(tbl, function(key, value)
								return value > 40
							end)
							assert(result == true, "Single element satisfies condition, should return true")
						end,
					},
					{
						Name = "Single element table that doesn't satisfy",
						Function = function()
							local tbl = {a = 42}
							local result = ExtendedTableLibrary.every(tbl, function(key, value)
								return value > 50
							end)
							assert(result == false, "Single element doesn't satisfy condition, should return false")
						end,
					},
				},
			},

			-- some tests
			{
				Name = "some",
				TestCases = {
					{
						Name = "At least one element satisfies condition",
						Function = function()
							local tbl = {a = 1, b = 3, c = 6, d = 9}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return value % 2 == 0
							end)
							assert(result == true, "At least one value is even, should return true")
						end,
					},
					{
						Name = "No elements satisfy condition",
						Function = function()
							local tbl = {a = 1, b = 3, c = 5, d = 7}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return value % 2 == 0
							end)
							assert(result == false, "No values are even, should return false")
						end,
					},
					{
						Name = "Empty table returns false",
						Function = function()
							local tbl = {}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return true -- Even always-true condition should return false for empty table
							end)
							assert(result == false, "Empty table should return false")
						end,
					},
					{
						Name = "All elements satisfy condition",
						Function = function()
							local tbl = {a = 2, b = 4, c = 6, d = 8}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return value % 2 == 0
							end)
							assert(result == true, "All values are even, should return true")
						end,
					},
					{
						Name = "Some string keys satisfy condition",
						Function = function()
							local tbl = {apple = 1, banana = 2, apricot = 3, cherry = 4}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return string.sub(key, 1, 1) == "a"
							end)
							assert(result == true, "Some keys start with 'a', should return true")
						end,
					},
					{
						Name = "Array where some elements satisfy condition",
						Function = function()
							local tbl = {5, 15, 25, 35, 45}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return value > 30
							end)
							assert(result == true, "Some values > 30, should return true")
						end,
					},
					{
						Name = "Array where no elements satisfy condition",
						Function = function()
							local tbl = {5, 15, 25}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return value > 30
							end)
							assert(result == false, "No values > 30, should return false")
						end,
					},
					{
						Name = "Mixed key types where some satisfy condition",
						Function = function()
							local tbl = {[1] = "one", ["two"] = 2, [true] = "yes"}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return type(key) == "number"
							end)
							assert(result == true, "Some keys are numbers, should return true")
						end,
					},
					{
						Name = "Single element table that satisfies",
						Function = function()
							local tbl = {a = 42}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return value > 40
							end)
							assert(result == true, "Single element satisfies condition, should return true")
						end,
					},
					{
						Name = "Single element table that doesn't satisfy",
						Function = function()
							local tbl = {a = 42}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return value > 50
							end)
							assert(result == false, "Single element doesn't satisfy condition, should return false")
						end,
					},
					{
						Name = "Mixed value types where some satisfy condition",
						Function = function()
							local tbl = {a = "hello", b = 42, c = true, d = {}}
							local result = ExtendedTableLibrary.some(tbl, function(key, value)
								return type(value) == "table"
							end)
							assert(result == true, "Some values are tables, should return true")
						end,
					},
				},
			},

			-- toSet tests
			{
				Name = "toSet",
				TestCases = {
					{
						Name = "Convert hash table to set",
						Function = function()
							local tbl = {a = 1, b = 2, c = 3}
							local result = ExtendedTableLibrary.toSet(tbl)
							local expected = {a = true, b = true, c = true}
							assert(deepEqual(result, expected), "Should convert all keys to true values")
						end,
					},
					{
						Name = "Convert array to set",
						Function = function()
							local tbl = {"apple", "banana", "cherry"}
							local result = ExtendedTableLibrary.toSet(tbl)
							local expected = {[1] = true, [2] = true, [3] = true}
							assert(deepEqual(result, expected), "Should convert array indices to true values")
						end,
					},
					{
						Name = "Convert empty table to set",
						Function = function()
							local tbl = {}
							local result = ExtendedTableLibrary.toSet(tbl)
							local expected = {}
							assert(deepEqual(result, expected), "Empty table should produce empty set")
						end,
					},
					{
						Name = "Convert mixed table to set",
						Function = function()
							local tbl = {1, 2, a = "hello", b = "world", [5] = "five"}
							local result = ExtendedTableLibrary.toSet(tbl)
							local expected = {[1] = true, [2] = true, a = true, b = true, [5] = true}
							assert(deepEqual(result, expected), "Should convert all keys including mixed types")
						end,
					},
					{
						Name = "Convert table with various key types to set",
						Function = function()
							local keyTable = {}
							local tbl = {
								[1] = "number key",
								["string"] = "string key",
								[true] = "boolean key",
								[keyTable] = "table key"
							}
							local result = ExtendedTableLibrary.toSet(tbl)
							local expected = {
								[1] = true,
								["string"] = true,
								[true] = true,
								[keyTable] = true
							}
							assert(deepEqual(result, expected), "Should preserve all key types as set keys")
						end,
					},
					{
						Name = "Original table values are ignored",
						Function = function()
							local tbl = {a = "complex", b = {nested = "table"}, c = 42, d = false, e = nil}
							local result = ExtendedTableLibrary.toSet(tbl)

							-- Check that all non-nil keys are present with value true
							assert(result.a == true, "Should convert key 'a' to true regardless of original value")
							assert(result.b == true, "Should convert key 'b' to true regardless of original value")
							assert(result.c == true, "Should convert key 'c' to true regardless of original value")
							assert(result.d == true, "Should convert key 'd' to true regardless of original value")
							assert(result.e == nil, "Key 'e' should not exist since original value was nil")
						end,
					},
					{
						Name = "Set can be used for membership testing",
						Function = function()
							local tbl = {apple = 1, banana = 2, cherry = 3}
							local set = ExtendedTableLibrary.toSet(tbl)

							assert(set.apple == true, "Should be able to test membership of 'apple'")
							assert(set.banana == true, "Should be able to test membership of 'banana'")
							assert(set.cherry == true, "Should be able to test membership of 'cherry'")
							assert(set.grape == nil, "Should return nil for non-member 'grape'")

							-- Practical membership test
							local function isMember(item)
								return set[item] == true
							end

							assert(isMember("apple") == true, "Membership test should work for existing key")
							assert(isMember("grape") == false, "Membership test should work for non-existing key")
						end,
					},
					{
						Name = "Set preserves key references",
						Function = function()
							local keyTable1 = {id = 1}
							local keyTable2 = {id = 2}
							local tbl = {[keyTable1] = "first", [keyTable2] = "second"}
							local set = ExtendedTableLibrary.toSet(tbl)

							assert(set[keyTable1] == true, "Should preserve table key reference 1")
							assert(set[keyTable2] == true, "Should preserve table key reference 2")

							-- Test that it's the same reference
							local newTable = {id = 1}
							assert(set[newTable] == nil, "Different table with same content should not be a member")
						end,
					},
					{
						Name = "Single element table to set",
						Function = function()
							local tbl = {only = "value"}
							local result = ExtendedTableLibrary.toSet(tbl)
							local expected = {only = true}
							assert(deepEqual(result, expected), "Single element table should convert correctly")
						end,
					},
					{
						Name = "Sparse array to set",
						Function = function()
							local tbl = {[1] = "a", [5] = "e", [10] = "j"}
							local result = ExtendedTableLibrary.toSet(tbl)
							local expected = {[1] = true, [5] = true, [10] = true}
							assert(deepEqual(result, expected), "Sparse array should convert correctly")
						end,
					},
				},
			},
		}
	},
}

local totalTests = 0
local totalPassed = 0

local function runTests(testCase)
	local name = testCase.Name
	print(`Running test case: {name}`)

	if testCase.Enabled == false then
		print(`Test case "{name}" is disabled, skipping.`)
		return
	end

	if testCase.Description then
		print(`Description: {testCase.Description}`)
	end

	local func = testCase.Function
	local passed

	if func then
		totalTests += 1
		local input = testCase.Input or {}
		local expected = testCase.Expected

		local success, result = pcall(func :: any, unpack(input))
		if success then
			if result ~= expected then
				warn(`Test case "{name}" failed: Expected {expected}, got {result}`)
				passed = false
			else
				print(`Test case "{name}" passed.`)
				passed = true
				totalPassed += 1
			end
		else
			warn(`Test case "{name}" failed with error: {result}`)
			passed = false
		end
	end

	if testCase.TestCases then
		for _, test in testCase.TestCases do
			if runTests(test) == false then
				passed = false
			end
		end
	end

	return passed ~= false
end

local groupTested = 0
local groupPassed = 0

local testStartTime = os.clock()
warn("Starting tests...")

for _, testGroup in TestCases :: any do
	warn(`Running test group: {testGroup.Name}`)
	local start = os.clock()
	local passed = runTests(testGroup)
	if passed == true then
		groupTested += 1
		groupPassed += 1
	elseif passed == false then
		groupTested += 1
	end
	local duration = os.clock() - start
	warn(`Test group "{testGroup.Name}" completed in {duration} seconds.`)
end

local testEndTime = os.clock()
local totalDuration = testEndTime - testStartTime

warn(`Total tests run: {totalTests}, Passed: {totalPassed}, Failed: {totalTests - totalPassed}`)
warn(`Total test groups: {#TestCases}, Groups tested: {groupTested}`)
warn(`Groups passed: {groupPassed}, Groups failed: {groupTested - groupPassed}`)
warn(`Total duration: {totalDuration} seconds`)
warn(`All tests completed.`)
