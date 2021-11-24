local DateTimeWidget = require("ui/widget/datetimewidget")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local _ = require("gettext")
local T = require("ffi/util").template

local GoToBed = WidgetContainer:new{
        name = "gotobed",
        time = false,
}

function GoToBed:init()
        self.ui.menu:registerToMainMenu(self)
end

function GoToBed:enabled()
        return self.time
end

function GoToBed:addToMainMenu(menu_items)
        menu_items.gotobed = {
                -- main menu item
                text_func = function ()
                        if self:enabled() then
                                return T(
                                        _("Bedtime is at %1:%1"),
                                        string.format("%02d", self.time.hour),
                                        string.format("%02d", self.time.min)
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
                                                        self.time = time
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
                                        self.time = false
                                        touchmenu_instance:updateItems()
                                end
                        },

                }
        }
end

return GoToBed
