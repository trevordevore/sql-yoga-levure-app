script "todo_window stack behavior"
on saveStackRequest
  set the text of field "Search" to empty
  set the hilite of button "HideCompleted" to false
  dispatch "ResetControl" to group "ProjectsPeople"
  dispatch "ResetControl" to group "ToDo"
  pass saveStackRequest
end saveStackRequest
