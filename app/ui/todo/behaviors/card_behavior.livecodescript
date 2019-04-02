script "To-Do Card Behavior"
on PreOpenView pHasBeenOpened
  ## EQUIVALENT TO preOpenCard BUT WITH A PARAMETER LETTING YOU KNOW
  ## IF THIS CARD HAS BEEN OPENED DURING THE APPLICATION SESSION.
  if not pHasBeenOpened then
    local tStack

    ## initialize fonts, button sizes, etc.
    FormatCardControlsForPlatform ## see libControlFormatter stack script
    put the long id of stack "To Do Data Grid Templates" into tStack
    dispatch "FormatCardControlsForPlatform" to card "ProjectsPeople" of tStack
    dispatch "FormatCardControlsForPlatform" to card "To-Do" of tStack

    uiReset
    uiPopulateProjectsAndPeople
  end if
end PreOpenView


on OpenView pHasBeenOpened
    ## EQUIVALENT TO openCard BUT WITH A PARAMETER LETTING YOU KNOW
    ## IF THIS CARD HAS BEEN OPENED DURING THE APPLICATION SESSION.

end OpenView


on ResizeView pWidth, pHeight, pOldWidth, pOldHeight
  ## EQUIVALENT TO resizeStack BUT SENT WHENEVER RESIZING OF CONTROLS MIGHT
  ## BE NECESSARY SUCH AS WHEN NAVIGATING BETWEEN CARDS IN A STACK
  ## THAT IS ALREADY OPEN
  local tRect

  ## Resize toolbar
  put the rect of group "Toolbar" into tRect
  put pWidth into item 3 of tRect
  set the rect of group "Toolbar" to tRect ## see resizeControl in Toolbar group for rest of the story...

  ## Resize left column
  put 0 into item 1 of tRect
  put the bottom of group "Toolbar" into item 2 of tRect
  put 200 into item 3 of tRect
  put pHeight into item 4 of tRect
  set the rect of group "ProjectsPeople" to tRect

  ## Resize To-Dos (base off of top and right of left column)
  put item 3 of tRect into item 1 of tRect
  put pWidth into item 3 of tRect
  set the rect of group "ToDo" to tRect

  ## Resize H Divider
  put the rect of graphic "HDivider" into tRect
  put pHeight into item 4 of tRect
  set the rect of graphic "HDivider" to tRect
end ResizeView


command uiReset
  lock screen
  set the text of field "Search" to empty
  set the dgData of group "ProjectsPeople" to empty
  set the dgData of group "ToDo" to empty
  set the hilite of button "HideCompleted" to false
  unlock screen
end uiReset


command uiCreateProject
  local tRecordA, tError

  ## Create a SQL Record object for 'projects' table
  put sqlrecord_createObject("projects") into tRecordA

  ## Set name property of object
  sqlrecord_set tRecordA, "name", "New Project"

  ## Create record in the database
  sqlrecord_create tRecordA
  put the result into tError

  if tError is empty then
    ## Refresh list
    lock screen
    RefreshProjectsPeopleList

    ## select new record (uSelectedProjectID is a custom property defined in group script)
    set the uSelectedProjectID of group "ProjectsPeople" to tRecordA["id"]

    ## tell Data Grid to select all text when field editor is opened
    set the dgTemplateFieldEditor["select text"] of group "ProjectsPeople" to true

    ## open field editor so that user can change name.
    dispatch "EditKeyOfIndex" to group "ProjectsPeople" with "name", \
          the dgHilitedIndex of group "ProjectsPeople"
    unlock screen
  end if

  if tError is not empty then
    answer "Error creating project:" && tError & "."
  end if
end uiCreateProject


command uiDeleteProject
  local tError, tProjectId, tRecordA

  ## Get id of project selected in left column
  put the uSelectedProjectID of group "ProjectsPeople" into tProjectId

  ## Create a SQL Record object for 'projects'
  put sqlrecord_createObject("projects") into tRecordA

  ## Fill in primary key field for 'projects'
  sqlrecord_set tRecordA, "id", tProjectId

  ## Delete record
  sqlrecord_delete tRecordA
  put the result into tError

  if tError is empty then
    ## Refresh list
    RefreshProjectsPeopleList
  end if

  if tError is not empty then
    answer "Error deleting project:" && tError & "."
  end if
end uiDeleteProject


command uiCreatePerson
  local tError, tRecordA

  ## Create a SQL Record object for 'people' table
  put sqlrecord_createObject("people") into tRecordA

  ## Set name property of object
  sqlrecord_set tRecordA, "name", "New Person"

  ## Create record in the database
  sqlrecord_create tRecordA
  put the result into tError

  if tError is empty then
    ## Refresh list, select new record and open field editor
    ## so that user can change name.
    lock screen
    RefreshProjectsPeopleList
    set the uSelectedPersonID of group "ProjectsPeople" to tRecordA["id"]
    set the dgTemplateFieldEditor["select text"] of group "ProjectsPeople" to true
    dispatch "EditKeyOfIndex" to group "ProjectsPeople" with "name", the dgHilitedIndex of group "ProjectsPeople"
    unlock screen
  end if

  if tError is not empty then
    answer "Error creating person:" && tError & "."
  end if
end uiCreatePerson


command uiDeletePerson
  local tError, tPersonId, tRecordA

  ## Get id of person selected in left column
  put the uSelectedPersonID of group "ProjectsPeople" into tPersonId

  ## Create a SQL Record object for 'people'
  put sqlrecord_createObject("people") into tRecordA

  ## Fill in primary key field for 'people'
  sqlrecord_set tRecordA, "id", tPersonId

  ## Delete record
  sqlrecord_delete tRecordA
  put the result into tError

  if tError is empty then
    ## Refresh list
    RefreshProjectsPeopleList
  end if

  if tError is not empty then
    answer "Error deleting person:" && tError & "."
  end if
end uiDeletePerson


command uiCreateToDo
  local tError, tProjectId, tRecordA

  put the uSelectedProjectID of group "ProjectsPeople" into tProjectId

  if tProjectId < 1 then
    put "no project selected" into tError
  end if

  if tError is empty then
    ## Create new SQL Record object for todo_items table
    put sqlrecord_createObject("todo_items") into tRecordA

    ## Set properties of object
    sqlrecord_set tRecordA, "name", "New Task"
    sqlrecord_set tRecordA, "project_id", tProjectId
    sqlrecord_set tRecordA, "sequence", NextSequenceForProject(tProjectId)

    ## Create record in the database
    sqlrecord_create tRecordA
    put the result into tError
  end if

  ## Add new record to Data Grid and open for editing
  if tError is empty then
    ## Refresh list, select new record and open field editor
    ## so that user can change name.
    lock screen
    RefreshToDoList
    set the uSelectedID of group "ToDo" to tRecordA["id"]
    set the dgTemplateFieldEditor["select text"] of group "ToDo" to true
    dispatch "EditKeyOfIndex" to group "ToDo" with "name", the dgHilitedIndex of group "ToDo"
    unlock screen
  end if

  if tError is not empty then
    answer "Error creating to-do item:" && tError & "."
  end if
end uiCreateToDo


command uiDeleteToDo
  local tError, tRecordA, tToDoId

  ## Get id of project selected in left column
  put the uSelectedID of group "ToDo" into tToDoId

  ## Create a SQL Record object for 'projects'
  put sqlrecord_createObject("todo_items") into tRecordA

  ## Fill in primary key field for 'projects'
  sqlrecord_set tRecordA, "id", tToDoId

  ## Delete record
  sqlrecord_delete tRecordA
  put the result into tError

  if tError is empty then
    ## Refresh list
    RefreshToDoList
  end if

  if tError is not empty then
    answer "Error deleting to-do item:" && tError & "."
  end if
end uiDeleteToDo


command uiPopulateProjectsAndPeople
  local tError, tDataA, tQueryA, tNextIndex

  ##
  ## Projects Title
  ##
  put "Projects" into tDataA[1]["name"]

  ##
  ## Project Records
  ##
  ## Create a SQL Query object
  put sqlquery_createObject("projects") into tQueryA

  ## Specify how results should be sorted
  sqlquery_set tQueryA, "order by", "name"

  ## Retrieve Projects data from database and convert to
  ## a numerically indexed array. First project record
  ## will start at tDataA[2] since tDataA[1] is already
  ## filled in.
  sqlquery_retrieveAsRecords tQueryA, tDataA
  put the result into tError

  ##
  ## People Title
  ##
  if tError is empty then
    ## item 2 of the extents is the current number of records
    ## already in the tDataA array variable.
    put item 2 of line 1 of the extents of tDataA + 1 into tNextIndex
    put "People" into tDataA[ tNextIndex ]["name"]
  end if

  ##
  ## People Records
  ##
  if tError is empty then
    ## Retrieve People data from database and convert to
    ## a numerically indexed array. First person record
    ## will start at tDataA[ tNextIndex + 1]
    put sqlquery_createObject("people") into tQueryA
    sqlquery_set tQueryA, "order by", "name"
    sqlquery_retrieveAsRecords tQueryA, tDataA
    put the result into tError
  end if

  if tError is empty then
    ## Assign the array directly to a Data Grid
    set the dgData of group "ProjectsPeople" to tDataA
  end if

  if tError is not empty then
    answer "Error populating projects and people:" && tError & "."
  end if
end uiPopulateProjectsAndPeople


command uiPopulateToDos
  local tRecordsA, tError, tQueryA

  ## Create Query object
  put sqlquery_createObject("todo_items") into tQueryA

  ## Filter by project or person?
  switch the uSelectedType of group "ProjectsPeople"
    case "project"
      sqlquery_addScope tQueryA, "of project", \
            the uSelectedProjectID of group "ProjectsPeople"
      sqlquery_set tQueryA, "order by", "todo_items.sequence"
      break

    case "person"
      sqlquery_addScope tQueryA, "of person", \
            the uSelectedPersonID of group "ProjectsPeople"
      break
  end switch

  ## User supplied search string?
  if the text of field "Search" is not empty then
    sqlquery_addScope tQueryA, "name contains", \
          sqlyoga_splitUserSearchString(the text of field "Search")
  end if

  ## Filter out completed?
  if the hilite of button "HideCompleted" then
    sqlquery_addScope tQueryA, "not completed"
  end if

  ## Query database
  sqlquery_retrieveAsRecords tQueryA, tRecordsA
  put the result into tError

  if tError is empty then
    set the dgData of group "ToDo" to tRecordsA
  end if

  if tError is not empty then
    answer "Error populating to-do items:" && tError & "."
  end if
end uiPopulateToDos


## Call when search conditions haven't changed but
## data may have. Brute force way to update UI after data is changed.
command RefreshToDoList
  local tPercent, tSelLineNo

  lock screen
  put the dgVScrollPercent of group "ToDo" into tPercent
  put the dgHilitedLine of group "ToDo" into tSelLineNo
  uiPopulateToDos
  set the dgVScrollPercent of group "ToDo" to tPercent
  set the dgHilitedLine of group "ToDo" to min(tSelLineNo, the dgNumberOfLines of group "ToDo")
  unlock screen
end RefreshToDoList


## Call when person or project is added/deleted.
## Brute force way to update UI after data is changed.
command RefreshProjectsPeopleList
  local tPercent, tSelLineNo, tLineToSelect

  lock screen
  put the dgVScrollPercent of group "ProjectsPeople" into tPercent
  put the dgHilitedLine of group "ProjectsPeople" into tSelLineNo
  uiPopulateProjectsAndPeople
  set the dgVScrollPercent of group "ProjectsPeople" to tPercent
  put min(tSelLineNo, the dgNumberOfLines of group "ProjectsPeople") into tLineToSelect

  ## Look for next selectable line
  repeat with i = tLineToSelect down to 1
    if the uIndexCanBeSelected[ i ] of group "ProjectsPeople" then
      set the dgHilitedLines of group "ProjectsPeople" to i
      exit repeat
    end if
  end repeat

  uiPopulateToDos
  unlock screen
end RefreshProjectsPeopleList


command uiRemovePersonFromTodo pPersonID
  local tError, tToDoId, tPersonA, tToDoA

  ## Get selected to-do database id
  put the uSelectedID of group "ToDo" into tToDoId

  ## Create SQL Record objects for person and to-do
  put sqlrecord_createObject("people") into tPersonA
  put sqlrecord_createObject("todo_items") into tToDoA

  ## Just set the fields that are used to link records together
  sqlrecord_set tPersonA, "id", pPersonID
  sqlrecord_set tToDoA, "id", tToDoId

  sqlrecord_unlink tPersonA, tToDoA
  put the result into tError

  if tError is empty then
    ## Refresh list
    RefreshToDoList
  end if

  if tError is not empty then
    answer "Error removing person from to-do item:" && tError & "."
  end if
end uiRemovePersonFromTodo


command LinkPersonWithToDo pPersonID, pToDoID
  local tError, tPersonA, tToDoA

  ## Create SQL Record objects for person and to-do
  put sqlrecord_createObject("people") into tPersonA
  put sqlrecord_createObject("todo_items") into tToDoA

  ## Just set the fields that are used to link records together
  sqlrecord_set tPersonA, "id", pPersonID
  sqlrecord_set tToDoA, "id", pToDoID

  ## Let SQL Yoga fill in the people_todo table for you
  try
    sqlrecord_link tPersonA, tToDoA
    put the result into tError
  catch e
    ## If person is already linked to to-do item then
    ## database will complain and error will be thrown.
    ## Just catch it and move along...
  end try

  if tError is empty then
    ## Refresh list
    RefreshToDoList
  end if

  if tError is not empty then
    answer "Error linking person to to-do item:" && tError & "."
  end if
end LinkPersonWithToDo


function NextSequenceForProject pProjectID
  local tQueryA, tData

  put sqlquery_createObject("todo_items") into tQueryA
  sqlquery_set tQueryA, "select clause", "MAX(sequence)"
  sqlquery_set tQueryA, "conditions", "project_id is :1", pProjectID
  put sqlquery_retrieveAsData(tQueryA) into tData
  if the result is empty then
    return tData + 1
  else
    return 0
  end if
end NextSequenceForProject
