script "Projects People Row Behavior"
-- This script defines the behavior of your data grid's custom template. This behavior
-- only applies to 'forms' and not 'tables'.

on FillInData pDataArray
   -- This message is sent when the Data Grid needs to populate
   -- this template with the data from a record. pDataArray is an
   -- an array containing the records data.
   -- You do not need to resize any of your template's controls in
   -- this message. All resizing should be handled in resizeControl.

   ## SQL Record objects have a @table key specifying the table
   ## the object is associated with. Use presence of value in that key
   ##  to determine how row should be formatted.
   if pDataArray["@table"] is not empty then
      set the leftmargin of field "Label" of me to 20
      set the textstyle of field "Label" of me to empty
   else
      set the leftmargin of field "Label" of me to 8
      set the textstyle of field "Label" of me to "bold"
   end if

   set the text of field "Label" of me to pDataArray["name"]
end FillInData


on LayoutControl pControlRect
   local theFieldRect

   -- This message is sent when you should layout your template's controls.
   -- This is where you resize the 'Background' graphic, resize fields and
   -- position objects.
   -- For fixed height data grid forms you can use items 1 through 4 of pControlRect as
   -- boundaries for laying out your controls.
   -- For variable height data grid forms you can use items 1 through 3 of pControlRect as
   -- boundaries, expanding the height of your control as needed.

   -- Example:
   put the rect of field "Label" of me into theFieldRect
   put item 3 of pControlRect - 5 into item 3 of theFieldRect
   set the rect of field "Label" of me to theFieldRect

   set the rect of graphic "Background" of me to pControlRect
end LayoutControl


setprop dgHilite pBoolean
   -- This custom property is set when the highlight of your custom template has
   -- changed. By default the "Background" graphic will be highlighted for you.
   -- You only add script here if you want to further customize the highlight.

   -- Example:
   if pBoolean then
      set the foregroundcolor of me to the dgProp["hilited text color"] of the dgControl of me
   else
      set the foregroundcolor of me to empty
   end if
end dgHilite


getprop dgDataControl
   -- Required by library so that it can locate your control.
   return the long id of me
end dgDataControl


on mouseDown pMouseBtnNum
   ## Don't allow selection of Projects and People titles
   if the uIndexCanBeSelected[the dgIndex of me] of me then
      pass mouseDown
   end if
end mouseDown


## Sent whenever a request is made to edit a particular key in the Data Grid
on EditValue pKey
   ## Only editable key is "name"
   EditFieldText the long id of field "Label" of me, the dgIndex of me, pKey
end EditValue


on mouseDoubleUp pMouseBtnNum
   local theKey

   -- Example of how to edit the contents of a field.
   -- By passing the index of the record associated with copy of this template being displayed and
   -- a key (array key) the data grid will automatically save the changes the user
   -- makes and refresh the UI by calling FillInData and resizeControl.
   if pMouseBtnNum is 1 AND the uIndexCanBeSelected[the dgIndex of me] of me then
      if the dgProps["allow editing"] of the dgControl of me then
         switch the short name of the target
            case "Label"
               put "name" into theKey
               EditKeyOfIndex theKey, the dgIndex of me
               break
         end switch
      end if
   end if

   pass mouseDoubleUp
end mouseDoubleUp
