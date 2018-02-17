script "libControlFormatter"
--> Declarations

constant kSystemFonts = "Lucida Grande,Tahoma"

--> all handlers

local sSettingsA


on libraryStack
    if the long id of the target is not the long id of me then pass libraryStack

    ## calculate scrollbar width for platform
    switch the platform
        case "win32"
            put queryregistry("HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics\ScollWidth") into theValue
            if theValue is an integer then put abs(theValue/15) into sSettingsA["scrollbarWidth"]
            else put 16 into sSettingsA["scrollbarWidth"]
            break
        case "macos"
        default
            put 15 into sSettingsA["scrollbarWidth"]
    end switch
end libraryStack


command FormatCardControlsForPlatform pCard
   local i,theButtonTopMargin,theControl,theFieldTopMargin

   if pCard is empty then
      put the long id of this card into pCard
   end if

   ## Note: empty textfont means we handle formatting.
   ## textfont means there are custom settings so don't mess with besides
   ## setting to effective font
   repeat with i = 1 to the number of fields of pCard
      put the long id of field i of pCard into theControl
      _FormatControlForPlatform theControl
   end repeat

   repeat with i = 1 to the number of buttons of pCard
      put the long id of button i of pCard into theControl
      _FormatControlForPlatform theControl
   end repeat

   repeat with i = 1 to the number of graphics of pCard
      put the long id of graphic i of pCard into theControl
      _FormatControlForPlatform theControl
   end repeat

   repeat with i = 1 to the number of groups of pCard
      put the long id of group i of pCard into theControl
      _FormatControlForPlatform theControl
   end repeat
end FormatCardControlsForPlatform


private command _FormatControlForPlatform pControl
   put item 2 of FieldMargins() into theFieldTopMargin
   put item 2 of ButtonMargins() into theButtonTopMargin
   put item 2 of MenuMargins() into theMenuTopMargin

   ## menu style OS X: 4, Windows : 5

   switch word 1 of pControl
      case "field"
         ## Editable fields get readjusted
         ## Label fields ("lbl" prefix) get readjusted
         ## Label fields...
         if char 1 to 3 of the short name of pControl is "lbl" then
            ## Label Field
            _FormatLabelFieldForPlatform pControl
         else
            if not the locktext of pControl then
               set the topmargin of pControl to theFieldTopMargin
            end if

            resetTextPropsOnControl pControl
         end if
         break
      case "button"
         resetTextPropsOnControl pControl

         put the style of pControl into theStyle
         if theStyle is among the items of "standard,radioButton,checkbox" then
            ResizeToFitLabel pControl
            set the topmargin of pControl to theButtonTopMargin
         else if theStyle is "menu" then
            if the showname of pControl then
               set the topmargin of pControl to theMenuTopMargin
            end if
         end if
         break
      case "group"
         if the scrollbarwidth of pControl > 0 then
            set the scrollbarwidth of pControl to ScrollBarWidthForPlatform()
         end if
         break
      case "graphic"
         if the shiftkey is down then breakpoint
         resetTextPropsOnControl pControl
         break
      case "scrollbar"
         if the style of pControl is "scrollbar" then
            if the orientation of pControl is "vertical" then
               set the width of pControl to ScrollBarWidthForPlatform()
            else
               set the height of pControl to ScrollBarWidthForPlatform()
            end if
         end if
         break
   end switch
end _FormatControlForPlatform


private command _FormatLabelFieldForPlatform pField
    put item 2 of FieldMargins() into theFieldTopMargin
    set the topmargin of pField to theFieldTopMargin
    resetTextPropsOnControl pField

    if the dontwrap of pField then
        ResizeLabelFieldtoFit pField
    else
        ResizeFieldHeightToFitText pField
    end if
end _FormatLabelFieldForPlatform


command ResizeLabelFieldtoFit pField
    put the textalign of pField into theAlignment
    put the rect of pField into theRect
    put the dontwrap of pField into theDontWrap
    set the dontwrap of pField to true

    switch theAlignment
        case "left"
            put item 1 of theRect + the formattedwidth of pField into item 3 of theRect
            set the rect of pField to theRect
            break
        case "right"
            put item 3 of theRect - the formattedwidth of pField into item 1 of theRect
            set the rect of pField to theRect
            break
        case "center"
            lock screen
            put the loc of pField into theLoc
            set the width of pField to the formattedwidth of pField
            set the loc of pField to theLoc
            unlock screen
            break
    end switch
    set the dontwrap of pField to theDontWrap
end ResizeLabelFieldtoFit


command ResizeFieldHeightToFitText pField, pMaxHeight
    put the rect of pField into theRect
    if pMaxHeight is an integer then
        put min(item 2 of theRect + pMaxHeight, item 2 of theRect + the formattedheight of pField) into item 4 of theRect
    else
        put item 2 of theRect + the formattedheight of pField into item 4 of theRect
    end if
    subtract the bottommargin of pField from item 4 of theRect

    set the rect of pField to theRect
end ResizeFieldHeightToFitText


private command resetTextPropsOnControl pControl
    local theHeight,theSize,theStyle

    put the textfont of pControl into theFont
    if the textfont of pControl is not empty then
        set the wholematches to true

        ## Non-system fonts are maintained. System fonts
        ## are inherited.
        if theFont is among the items of kSystemFonts then
            put empty into theFont
        end if

        ## use this method so we can inherit fonts from groups
        put the textstyle of pControl into theStyle
        put the textsize of pControl into theSize
        put the textheight of pControl into theHeight
        set the textfont of pControl to empty
        set the textfont of pControl to theFont
        set the textstyle of pControl to theStyle
        set the textsize of pControl to theSize
        set the textheight of pControl to theHeight
    end if
end resetTextPropsOnControl


command ResizeToFitLabel pControl
    -----
    local theLoc
    local theTextAlign
    local theWidth
    -----
    -- http://developer.apple.com/documentation/UserExperience/Conceptual/OSXHIGuidelines/XHIGControls/chapter_18_section_2.html
    -- http://msdn.microsoft.com/en-us/library/aa511279.aspx#controlsizing
    switch word 1 of the long id of pControl
        case "button"
            lock screen
            put the textalign of pControl into theTextAlign
            switch theTextAlign
                case "left"
                    put the topleft of pControl into theLoc
                    break
                case "right"
                    put the topright of pControl into theLoc
                    break
                default
                    put the loc of pControl into theLoc
            end switch

            if the icon of pControl > 0 then
                put item 1 of ButtonIconDimensions(pControl) into theWidth
            end if
            add the formattedwidth of pControl to theWidth

            if the style of pControl is not among the items of "checkbox,radiobutton" and the opaque of pControl then
                add 20 to theWidth ## Left/right padding
                put max(theWidth, MinimumButtonWidth()) into theWidth
            end if

            set the width of pControl to theWidth + the rightmargin of pControl
            switch theTextAlign
                case "left"
                    set the topleft of pControl to theLoc
                    break
                case "right"
                    set the topright of pControl to theLoc
                    break
                default
                    set the loc of pControl to theLoc
            end switch
            unlock screen
            break
        case "field"
            ResizeLabelFieldtoFit pControl
            break
    end switch
end ResizeToFitLabel


function MinimumButtonWidth
    switch the platform
        case "windows"
            return 73
            break
        case "macos"
        default
            return 70
            break
    end switch
end MinimumButtonWidth


function ButtonIconDimensions pButton
    -----
    local theDimensions
    local theLabel
    -----
    put the label of pButton into theLabel
    set the label of pButton to space
    put the formattedwidth of pButton & comma & the formattedheight of pButton into theDimensions
    set the label of pButton to theLabel
    return theDimensions
end ButtonIconDimensions


function ButtonMargins
    if the platform is "MacOS" then
        put 8,5,8,8 into theMargins
    else
        put 8,7,8,8 into theMargins
    end if
    return theMargins
end ButtonMargins


function FieldMargins
    if the platform is "MacOS" then
        put 8,6,8,8 into theMargins
    else
        put 8,8,8,8 into theMargins
    end if
    return theMargins
end FieldMargins


function MenuMargins
    if the platform is "MacOS" then
        put 8,4,8,8 into theMargins
    else
        put 8,6,8,8 into theMargins
    end if
    return theMargins
end MenuMargins


function ScrollBarWidthForPlatform
    return sSettingsA["scrollbarWidth"]
end ScrollBarWidthForPlatform
