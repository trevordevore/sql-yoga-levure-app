script "Toolbar Behavior"
on resizeControl
   if the target is not me then pass resizeControl
   
   set the lockLoc of me to true
   set the rect of graphic "ToolbarBackdrop" to the rect of me
   set the right of group "Filters" of me to the right of me  - 20
   put the rect of graphic "VDivider" of me into theRect
   put the right of me into item 3 of theRect
   set the rect of graphic "VDivider" of me to theRect 
   set the lockLoc of me to false
end resizeControl
