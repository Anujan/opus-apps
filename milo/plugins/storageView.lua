local itemDB = require('itemDB')
local UI     = require('ui')

local colors = _G.colors
local device = _G.device

local storageView = UI.Window {
	title = 'Storage Options',
	index = 2,
	backgroundColor = colors.cyan,
	form = UI.Form {
		x = 1, y = 1, ex = -1, ey = -2,
		manualControls = true,
		[1] = UI.TextEntry {
			formLabel = 'Priority', formKey = 'priority',
			help = 'Larger values get precedence',
			limit = 4,
			validate = 'numeric',
			shadowText = 'Numeric priority',
		},
		[2] = UI.Checkbox {
			formLabel = 'Locked', formKey = 'lockWith',
			help = 'Locks chest to a single item type',
		},
		[3] = UI.Text {
			x = 16, ex = -2, y = 3,
			value = '',
		},
		[4] = UI.TextEntry {
			formLabel = 'Refresh', formKey = 'refreshInterval',
			help = 'Refresh periodically',
			limit = 4,
			validate = 'numeric',
			shadowText = 'seconds between refresh',
		},
		[5] = UI.TextArea {
			x = 12, ex = -2, y = 5,
			textColor = colors.yellow,
			value = 'Only specify if you are manually taking items out of this inventory. Value should be > 10',
		},
--[[
		[4] = UI.Checkbox {
			formLabel = 'Void', formKey = 'voidExcess',
			help = 'Void excess if locked - TODO',
			pruneEmpty = true,
		},
		[5] = UI.Checkbox {
			formLabel = 'Partition', formKey = 'partition',
			help = 'TODO',
			pruneEmpty = true,
		},
]]--
	},
}

function storageView:enable()
	UI.Window.enable(self)
	self:focusFirst()
end

function storageView:validate()
	return self.form:save()
end

function storageView:isValidType(node)
	local m = device[node.name]
	return m and m.pullItems and {
		name = 'Storage',
		value = 'storage',
		help = 'Use for item storage',
	}
end

function storageView:isValidFor(node)
	return node.mtype == 'storage'
end

function storageView:setNode(node)
	self.machine = node
	self.form:setValues(node)
	self.form[3].value = node.lock and itemDB:getName(node.lock) or ''
end

function storageView:eventHandler(event)
	if event.type == 'checkbox_change' and event.element.formKey == 'lockWith' then
		if event.checked then
			if device[self.machine.name] and device[self.machine.name].list then
				local _, slot = next(device[self.machine.name].list())
				if slot then
					self.machine.lock = itemDB:makeKey(slot)
					self.form[3].value = itemDB:getName(slot)
				else
					self:emit({
						type = 'general_error',
						field = event.element,
						message = 'The chest must contain the item to lock' })
					self.form[3].value = false
					self.form[3]:draw()
				end
			end
		else
			self.machine.lock = nil
			self.form[3].value = ''
		end
		self.form[3]:draw()
	end
end

UI:getPage('nodeWizard').wizard:add({ storage = storageView })
