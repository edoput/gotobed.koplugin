-- gotobed is a koreader plugin to shut down the device at bedtime
--
-- TODO(edoput) this will always shut down the device after betime
-- even when the device is on standby. Listen for standby events
-- and cancel the poweroff.

-- ui
local DateTimeWidget = require("ui/widget/datetimewidget")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

-- persistence
local LuaSettings = require("luasettings")
local DataStorage = require("datastorage")

-- i18n
local _ = require("gettext")
local T = require("ffi/util").template

-- debug
local logger = require("logger")


local GoToBed = WidgetContainer:new{
        name = "gotobed",
        settings = nil, -- user settings { hour = h, min = m }
	timeout = 60, -- callback timeout in seconds
	callback = nil,
}

function GoToBed:init()
   if not self.settings then
      self.settings = LuaSettings:open(DataStorage:getSettingsDir() .. "/gotobed.lua")
   end
   self:setup()
   -- previously scheduled callbacks must be cleared
   self.ui.menu:registerToMainMenu(self)
end

function GoToBed:enabled()
   return self.settings:readSetting("bedtime", 0) ~= 0
end

function GoToBed:schedule()
   return self.settings:readSetting("bedtime")
end

function GoToBed:setup()
   self.callback = function () self:run() end
   UIManager:scheduleIn(self.timeout, self.callback)
end

function GoToBed:teardown()
   if self.callback ~= nil then
      UIManager:unschedule(self.callback)
   end
   self.callback = nil
end

-- callback
function GoToBed:run()
   if not self:enabled() then
      return
   end
   local schedule = self:schedule()
   local now = os.date("*t")
   if schedule.hour >= now.hour and schedule.min >= now.min then
      -- TODO(edoput) send a message
      UIManager.poweroff_action()
      return
   end
   UIManager:scheduleIn(self.timeout, self.callback)
end

function GoToBed:addToMainMenu(menu_items)
   menu_items.gotobed = {
      -- main menu item
      text_func = function ()
	 if self:enabled() then
	    local bedtime = self.settings:readSetting("bedtime", { hour = 0, min = 0})
	    return T(
	       _("Bedtime is at %1:%2"),
	       string.format("%02d", bedtime.hour),
	       string.format("%02d", bedtime.min)
	    )
	 else
	    return _("Set up bedtime")
	 end
      end,
      -- interaction with menu item
      sub_item_table = {
	 -- set bedtime
	 {
	    text = _("Set bedtime"),
	    keep_menu_open = true,
	    callback = function(touchmenu_instance)
	       local now_t = os.date("*t")
	       local time_picker = DateTimeWidget:new{
		  is_date = false,
		  hour = now_t.hour,
		  min = now_t.min,
		  -- ok_text = _("Confirm"),
		  title_text = _("Set bedtime"),
		  info_text = _("Enter a time in hours and minutes."),
		  callback = function(time)
		     -- UI
		     touchmenu_instance:closeMenu()
		     local confirmation = InfoMessage:new{
			text = T(_("Bedtime is at %1:%2"),
				 string.format("%02d", time.hour),
				 string.format("%02d", time.min)
			),
			timeout = 5,
		     }
		     UIManager:show(confirmation)
		     -- actually save new value
		     self.settings:saveSetting("bedtime", {hour = time.hour, min = time.min})
		     -- and persist to disk
		     self.settings:flush()
		     -- remove previously scheduled callbacks
		     self:teardown()
		     -- setup callback
		     self:setup()
		     -- show current bedtime in menu
		     touchmenu_instance:updateItems()
		  end
	       }
	       UIManager:show(time_picker)
	    end
	 },
	 -- disable bedtime
	 {
	    text = _("Disable bedtime"),
	    keep_menu_open = true,
	    enabled_func = function() return self:enabled() end,
	    callback = function(touchmenu_instance)
	       self.settings:delSetting("bedtime")
	       self.settings:flush()
	       self:teardown()
	       touchmenu_instance:updateItems()
	    end
	 },
	 
      }
   }
end

return GoToBed
