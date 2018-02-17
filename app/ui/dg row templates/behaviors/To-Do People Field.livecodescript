script "To-Do People Field Behavior"
on mouseUp pMouseBtnNum
   if pMouseBtnNum is 1 then
      put the clickCharChunk into theChunk
      if theChunk is not empty and the imagesource of theChunk is "1025" then
         ## User clicked on delete icon.
         ## Get id from the a href link and remove from todo
         put the linkText of theChunk into thePersonID
         ## Commands that refresh data grid have to be executed outside
         ## of the engine event. Send in 0 accomplishes this
         send "uiRemovePersonFromTodo thePersonID" to me in 0 seconds
      end if
   end if
   
   pass mouseUp
end mouseUp
