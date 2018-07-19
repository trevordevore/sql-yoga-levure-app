script "To-Do Row Template Behavior"
-- This script defines the behavior of your data grid's custom template. This behavior
-- only applies to 'forms' and not 'tables'.

on FillInData pDataArray
   local thePeople

   -- This message is sent when the Data Grid needs to populate
   -- this template with the data from a record. pDataArray is an
   -- an array containing the records data.
   -- You do not need to resize any of your template's controls in
   -- this message. All resizing should be handled in resizeControl.

   set the text of field "Name" of me to pDataArray["name"]
   set the hilite of button "Completed" of me to pDataArray["completed"]

   ## Loop though "people_todo" nested array to display people associated
   ## with this to-do item.
   repeat with i = 1 to item 2 of line 1 of the extents of pDataArray["people_todo"]
      ## Create string: <p><a href=ID><img src=1025></a>NAME OF PERSON</p>
      put "<p><a href=" & pDataArray["people_todo"][ i ]["people"]["id"] & "><img src=1025></a>  " & \
             pDataArray["people_todo"][ i ]["people"]["name"] & "</p>" after thePeople
   end repeat
   delete the last char of thePeople

   set the htmltext of field "People" of me to thePeople
   set the visible of field "People" of me to thePeople is not empty
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

   put the rect of field "Name" of me into theFieldRect
   put the item 3 of pControlRect into item 3 of theFieldRect
   set the rect of field "Name" of me to theFieldRect

   ## Resize height of people field to fit content.
   ## Since dontwrap of field is true we can set everything in one go.
   ## Otherwise we would have to set width first and then determine
   ## formattedHeight
   if the visible of field "People" of me then
      put the rect of field "People" of me into theRect
      put item 3 of pControlRect into item 3 of theRect
      put item 2 of theRect + the formattedHeight of field "People" of me into item 4 of theRect
      set the rect of field "People" of me to theRect
      put the bottom of field "People" of me into theBottom
   else
      put the bottom of field "Name" of me into theBottom
   end if

   ## Resize background
   put pControlRect into theRect
   put theBottom into item 4 of theRect
   set the rect of graphic "Background" of me to theRect
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


on mouseUp pMouseBtnNum
   if pMouseBtnNum is 1 then
      ## See if the user clicked on the "completed" button
      if the short name of the target is "completed" then
         ## Find to-do item in database that was clicked on
         sqlrecord_find "todo_items", the uSelectedID of the dgControl of me, \
                theRecordA
         put the result into theError

         if theError is empty then
            ## Update "completed" value for record
            put the hilite of button "completed" of me into theStatus
            sqlrecord_set theRecordA, "completed", theStatus
            sqlrecord_update theRecordA
            put the result into theError
         end if

         ## Update Data Grid
         if theError is empty then
            SetDataOfIndex the dgIndex of me, "completed", theStatus

            ## If UI is hiding completed items and this is complete
            ## then refresh display
            if the hilite of button "HideCompleted" and theStatus then
               ## Since this row is going to disappear and it is
               ## executing code we have to use send in time or
               ## the engine will complain.
               send "RefreshToDoList" to me in 0 seconds
            end if
         end if
      end if
   end if

   if theError is not empty then
      answer "Error updating completed status:" && theError & "."
   end if

   pass mouseUp
end mouseUp


## Sent whenever a request is made to edit a particular key in the Data Grid
on EditValue pKey
   ## Only editable key is "name"
   EditFieldText the long id of field "Name" of me, the dgIndex of me, pKey
end EditValue


on mouseDoubleUp pMouseBtnNum
   local theKey

   -- Example of how to edit the contents of a field.
   -- By passing the index of the record associated with copy of this template being displayed and
   -- a key (array key) the data grid will automatically save the changes the user
   -- makes and refresh the UI by calling FillInData and resizeControl.
   if pMouseBtnNum is 1 then
      if the dgProps["allow editing"] of the dgControl of me then
         switch the short name of the target
            case "Name"
               EditKeyOfIndex "name", the dgIndex of me
               break
         end switch
      end if
   end if

   pass mouseDoubleUp
end mouseDoubleUp
