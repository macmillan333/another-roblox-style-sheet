# Another Roblox Style Sheet
My shot at a Roblox Studio plugin that parses and applies style sheets in a custom format.

## How to use
After installing the plugin, you should see a `Style Sheets` toolbar in the `PLUGINS` tab, and an `Apply` button.

![image](https://github.com/user-attachments/assets/64aa0103-4e93-47d1-9924-b4bdee6475a7)

To use the plugin, first create a style sheet: a `ModuleScript` named `StyleSheet` under `StarterGui`. The format will be explained later.

![image](https://github.com/user-attachments/assets/7dc0012b-2b37-4033-a108-3f03a62ec8d5)

After you write your style sheet, click the `Apply` button to apply it to all applicable instances in `StarterGui`! If there's a mistake in your style sheet, a message box will pop up to show you the error message.

## An example style sheet

```Lua
local styleSheet = { }

styleSheet["#\"Confirm Dialog\" TextButton"] = {
	BackgroundColor3 = Color3.fromRGB(170, 0, 0),
	UICorner = {
		CornerRadius = UDim.new(0, 10)
	},
}

return styleSheet
```

When applied, the plugin will look for all `TextButton`s that are descendents of an instance named `Confirm Dialog`, then for each button:
* change their background color to RGB(170, 0, 0)
* create a `UICorner` if one doesn't exist
* change the `UICorner`'s radius to 10

## Style sheet format

```Lua
local styleSheet = { }

styleSheet["selector1"] = {
    Attribute1 = Value1,
    Attribute2 = Value2,
    UIGradient = { Attribute = Value },
    UIStroke = { Attribute = Value },
    UICorner = { Attribute = Value },
    UIPadding = { Attribute = Value },
}

styleSheet["selector2"] = {
    Attribute1 = Value1,
    Attribute2 = Value2
}

return styleSheet
```

As you can see, the style sheet is a Lua table where each key is a selector, and value is a table of attributes to apply to instances that match the selector.

### Selector

Similar to CSS, you can select instances in 1 of 3 ways:
* `ClassName`: by instance class
* `#InstanceName`: by instance name
* `.tagName`: by tags on the instance

These all support spaces, but you'll need to use quotation marks and escape them, as seen in the example above. Selectors do not currently support class/name/tags that contain quotation marks.

A selector can have multiple parts, meaning the latter parts are descendants of earlier parts.

### Appearance modifiers

To make it easier to set [appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers), you can set the `UIGradient`, `UIStroke`, `UICorner` and `UIPadding` attributes on the parent instances. So instead of:

```
styleSheet["TextButton"] = {
    Attribute1 = Value1,
    Attribute2 = Value2
}
styleSheet["TextButton UICorner"] = {
    UICornerAttribute1 = Value1,
    UICornerAttribute1 = Value2
}
```

You can set:

```
styleSheet["TextButton"] = {
    Attribute1 = Value1,
    Attribute2 = Value2,
    UICorner = {
        UICornerAttribute1 = Value1,
        UICornerAttribute1 = Value2,
    }
}
```

Another advantage of this is, if an instance matching the selector does not have the specified modifier, the plugin will create one when applying the style sheet. Likewise, if an instance has a modifier but the style sheet does not set it, the plugin will remove the modifier.
