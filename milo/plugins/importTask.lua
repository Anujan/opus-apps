local Milo = require('milo')

local ImportTask = {
	name = 'importer',
	priority = 20,
}

local function filter(a)
	return a.imports
end

function ImportTask:cycle(context)
	for inventory in context.storage:filterActive('machine', filter) do
		for _, entry in pairs(inventory.imports) do

			local function itemMatchesFilter(item)
				if not entry.ignoreDamage and not entry.ignoreNbtHash then
					return entry.filter[item.key]
				end

				for key in pairs(entry.filter) do
					local v = Milo:splitKey(key)
					if item.name == v.name and
						(entry.ignoreDamage or item.damage == v.damage) and
						(entry.ignoreNbtHash or item.nbtHash == v.nbtHash) then
						return true
					end
				end
			end

			local function matchesFilter(item)
				if not entry.filter then
					return true
				end

				if entry.blacklist then
					return not itemMatchesFilter(item)
				end

				return itemMatchesFilter(item)
			end

			local function importSlot(slotNo)
				local item = inventory.adapter.getItemMeta(slotNo)
				if item and matchesFilter(item) then
					context.storage:import(inventory.name, slotNo, item.count, item)
				end
			end

			if type(entry.slot) == 'number' then
				importSlot(entry.slot)
			else
				for i = 1, inventory.adapter.size() do
					importSlot(i)
				end
			end
		end
	end
end

Milo:registerTask(ImportTask)
