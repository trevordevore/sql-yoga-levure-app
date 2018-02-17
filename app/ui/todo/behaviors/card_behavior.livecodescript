script "To-Do Card Behavior"
on PreOpenView pHasBeenOpened
  ## EQUIVALENT TO preOpenCard BUT WITH A PARAMETER LETTING YOU KNOW
  ## IF THIS CARD HAS BEEN OPENED DURING THE APPLICATION SESSION.
  if not pHasBeenOpened then
    ## initialize fonts, button sizes, etc.
    FormatCardControlsForPlatform ## see libControlFormatter stack script
    put the long id of stack "To Do Data Grid Templates" into theStack
    dispatch "FormatCardControlsForPlatform" to card "ProjectsPeople" of theStack
    dispatch "FormatCardControlsForPlatform" to card "To-Do" of theStack

    if the platform is "macos" then
      set the dgProps["scrollbar corner offset"] of group "ToDo" to 15
    else
      set the dgProps["scrollbar corner offset"] of group "ToDo" to 0
    end if

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

  ## Resize toolbar
  put the rect of group "Toolbar" into theRect
  put pWidth into item 3 of theRect
  set the rect of group "Toolbar" to theRect ## see resizeControl in Toolbar group for rest of the story...

  ## Resize left column
  put 0 into item 1 of theRect
  put the bottom of group "Toolbar" into item 2 of theRect
  put 200 into item 3 of theRect
  put pHeight into item 4 of theRect
  set the rect of group "ProjectsPeople" to theRect

  ## Resize To-Dos (base off of top and right of left column)
  put item 3 of theRect into item 1 of theRect
  put pWidth into item 3 of theRect
  set the rect of group "ToDo" to theRect

  ## Resize H Divider
  put the rect of graphic "HDivider" into theRect
  put pHeight into item 4 of theRect
  set the rect of graphic "HDivider" to theRect
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
  ## Create a SQL Record object for 'projects' table
  put sqlrecord_createObject("projects") into theRecordA

  ## Set name property of object
  sqlrecord_set theRecordA, "name", "New Project"

  ## Create record in the database
  sqlrecord_create theRecordA
  put the result into theError

  if theError is empty then
    ## Refresh list
    lock screen
    RefreshProjectsPeopleList

    ## select new record (uSelectedProjectID is a custom property defined in group script)
    set the uSelectedProjectID of group "ProjectsPeople" to theRecordA["id"]

    ## tell Data Grid to select all text when field editor is opened
    set the dgTemplateFieldEditor["select text"] of group "ProjectsPeople" to true

    ## open field editor so that user can change name.
    dispatch "EditKeyOfIndex" to group "ProjectsPeople" with "name", \
          the dgHilitedIndex of group "ProjectsPeople"
    unlock screen
  end if

  if theError is not empty then
    answer "Error creating project:" && theError & "."
  end if
end uiCreateProject


command uiDeleteProject
  ## Get id of project selected in left column
  put the uSelectedProjectID of group "ProjectsPeople" into theProjectID

  ## Create a SQL Record object for 'projects'
  put sqlrecord_createObject("projects") into theRecordA

  ## Fill in primary key field for 'projects'
  sqlrecord_set theRecordA, "id", theProjectID

  ## Delete record
  sqlrecord_delete theRecordA
  put the result into theError

  if theError is empty then
    ## Refresh list
    RefreshProjectsPeopleList
  end if

  if theError is not empty then
    answer "Error deleting project:" && theError & "."
  end if
end uiDeleteProject


command uiCreatePerson
  ## Create a SQL Record object for 'people' table
  put sqlrecord_createObject("people") into theRecordA

  ## Set name property of object
  sqlrecord_set theRecordA, "name", "New Person"

  ## Create record in the database
  sqlrecord_create theRecordA
  put the result into theError

  if theError is empty then
    ## Refresh list, select new record and open field editor
    ## so that user can change name.
    lock screen
    RefreshProjectsPeopleList
    set the uSelectedPersonID of group "ProjectsPeople" to theRecordA["id"]
    set the dgTemplateFieldEditor["select text"] of group "ProjectsPeople" to true
    dispatch "EditKeyOfIndex" to group "ProjectsPeople" with "name", the dgHilitedIndex of group "ProjectsPeople"
    unlock screen
  end if

  if theError is not empty then
    answer "Error creating person:" && theError & "."
  end if
end uiCreatePerson


command uiDeletePerson
  ## Get id of person selected in left column
  put the uSelectedPersonID of group "ProjectsPeople" into thePersonID

  ## Create a SQL Record object for 'people'
  put sqlrecord_createObject("people") into theRecordA

  ## Fill in primary key field for 'people'
  sqlrecord_set theRecordA, "id", thePersonID

  ## Delete record
  sqlrecord_delete theRecordA
  put the result into theError

  if theError is empty then
    ## Refresh list
    RefreshProjectsPeopleList
  end if

  if theError is not empty then
    answer "Error deleting person:" && theError & "."
  end if
end uiDeletePerson


command uiCreateToDo
  put the uSelectedProjectID of group "ProjectsPeople" into theProjectID

  if theProjectID < 1 then
    put "no project selected" into theError
  end if

  if theError is empty then
    ## Create new SQL Record object for todo_items table
    put sqlrecord_createObject("todo_items") into theRecordA

    ## Set properties of object
    sqlrecord_set theRecordA, "name", "New Task"
    sqlrecord_set theRecordA, "project_id", theProjectID
    sqlrecord_set theRecordA, "sequence", NextSequenceForProject(theProjectID)

    ## Create record in the database
    sqlrecord_create theRecordA
    put the result into theError
  end if

  ## Add new record to Data Grid and open for editing
  if theError is empty then
    ## Refresh list, select new record and open field editor
    ## so that user can change name.
    lock screen
    RefreshToDoList
    set the uSelectedID of group "ToDo" to theRecordA["id"]
    set the dgTemplateFieldEditor["select text"] of group "ToDo" to true
    dispatch "EditKeyOfIndex" to group "ToDo" with "name", the dgHilitedIndex of group "ToDo"
    unlock screen
  end if

  if theError is not empty then
    answer "Error creating to-do item:" && theError & "."
  end if
end uiCreateToDo


command uiDeleteToDo
  ## Get id of project selected in left column
  put the uSelectedID of group "ToDo" into theToDoID

  ## Create a SQL Record object for 'projects'
  put sqlrecord_createObject("todo_items") into theRecordA

  ## Fill in primary key field for 'projects'
  sqlrecord_set theRecordA, "id", theToDoID

  ## Delete record
  sqlrecord_delete theRecordA
  put the result into theError

  if theError is empty then
    ## Refresh list
    RefreshToDoList
  end if

  if theError is not empty then
    answer "Error deleting to-do item:" && theError & "."
  end if
end uiDeleteToDo


command uiPopulateProjectsAndPeople
  ##
  ## Projects Title
  ##
  put "Projects" into theDataA[1]["name"]

  ##
  ## Project Records
  ##
  ## Create a SQL Query object
  put sqlquery_createObject("projects") into theQueryA

  ## Specify how results should be sorted
  sqlquery_set theQueryA, "order by", "name"

  ## Retrieve Projects data from database and convert to
  ## a numerically indexed array. First project record
  ## will start at theDataA[2] since theDataA[1] is already
  ## filled in.
  sqlquery_retrieveAsRecords theQueryA, theDataA
  put the result into theError

  ##
  ## People Title
  ##
  if theError is empty then
    ## item 2 of the extents is the current number of records
    ## already in the theDataA array variable.
    put item 2 of line 1 of the extents of theDataA + 1 into theNextIndex
    put "People" into theDataA[ theNextIndex ]["name"]
  end if

  ##
  ## People Records
  ##
  if theError is empty then
    ## Retrieve People data from database and convert to
    ## a numerically indexed array. First person record
    ## will start at theDataA[ theNextIndex + 1]
    put sqlquery_createObject("people") into theQueryA
    sqlquery_set theQueryA, "order by", "name"
    sqlquery_retrieveAsRecords theQueryA, theDataA
    put the result into theError
  end if

  if theError is empty then
    ## Assign the array directly to a Data Grid
    set the dgData of group "ProjectsPeople" to theDataA
  end if

  if theError is not empty then
    answer "Error populating projects and people:" && theError & "."
  end if
end uiPopulateProjectsAndPeople


command uiPopulateToDos
  local theRecordsA,theError

  ## Create Query object
  put sqlquery_createObject("todo_items") into theQueryA

  ## Filter by project or person?
  switch the uSelectedType of group "ProjectsPeople"
    case "project"
      sqlquery_addScope theQueryA, "of project", \
            the uSelectedProjectID of group "ProjectsPeople"
      sqlquery_set theQueryA, "order by", "todo_items.sequence"
      break

    case "person"
      sqlquery_addScope theQueryA, "of person", \
            the uSelectedPersonID of group "ProjectsPeople"
      break
  end switch

  ## User supplied search string?
  if the text of field "Search" is not empty then
    sqlquery_addScope theQueryA, "name contains", \
          sqlyoga_splitUserSearchString(the text of field "Search")
  end if

  ## Filter out completed?
  if the hilite of button "HideCompleted" then
    sqlquery_addScope theQueryA, "not completed"
  end if

  ## Query database
  sqlquery_retrieveAsRecords theQueryA, theRecordsA
  put the result into theError

  if theError is empty then
    set the dgData of group "ToDo" to theRecordsA
  end if

  if theError is not empty then
    answer "Error populating to-do items:" && theError & "."
  end if
end uiPopulateToDos


## Call when search conditions haven't changed but
## data may have. Brute force way to update UI after data is changed.
command RefreshToDoList
  lock screen
  put the dgVScrollPercent of group "ToDo" into thePercent
  put the dgHilitedLine of group "ToDo" into theSelLineNo
  uiPopulateToDos
  set the dgVScrollPercent of group "ToDo" to thePercent
  set the dgHilitedLine of group "ToDo" to min(theSelLineNo, the dgNumberOfLines of group "ToDo")
  unlock screen
end RefreshToDoList


## Call when person or project is added/deleted.
## Brute force way to update UI after data is changed.
command RefreshProjectsPeopleList
  lock screen
  put the dgVScrollPercent of group "ProjectsPeople" into thePercent
  put the dgHilitedLine of group "ProjectsPeople" into theSelLineNo
  uiPopulateProjectsAndPeople
  set the dgVScrollPercent of group "ProjectsPeople" to thePercent
  put min(theSelLineNo, the dgNumberOfLines of group "ProjectsPeople") into theLineToSelect

  ## Look for next selectable line
  repeat with i = theLineToSelect down to 1
    if the uIndexCanBeSelected[ i ] of group "ProjectsPeople" then
      set the dgHilitedLines of group "ProjectsPeople" to i
      exit repeat
    end if
  end repeat

  uiPopulateToDos
  unlock screen
end RefreshProjectsPeopleList


command uiRemovePersonFromTodo pPersonID
  ## Get selected to-do database id
  put the uSelectedID of group "ToDo" into theToDoID

  ## Create SQL Record objects for person and to-do
  put sqlrecord_createObject("people") into thePersonA
  put sqlrecord_createObject("todo_items") into theToDoA

  ## Just set the fields that are used to link records together
  sqlrecord_set thePersonA, "id", pPersonID
  sqlrecord_set theToDoA, "id", theToDoID

  sqlrecord_unlink thePersonA, theToDoA
  put the result into theError

  if theError is empty then
    ## Refresh list
    RefreshToDoList
  end if

  if theError is not empty then
    answer "Error removing person from to-do item:" && theError & "."
  end if
end uiRemovePersonFromTodo


command LinkPersonWithToDo pPersonID, pToDoID
  ## Create SQL Record objects for person and to-do
  put sqlrecord_createObject("people") into thePersonA
  put sqlrecord_createObject("todo_items") into theToDoA

  ## Just set the fields that are used to link records together
  sqlrecord_set thePersonA, "id", pPersonID
  sqlrecord_set theToDoA, "id", pToDoID

  ## Let SQL Yoga fill in the people_todo table for you
  try
    sqlrecord_link thePersonA, theToDoA
    put the result into theError
  catch e
    ## If person is already linked to to-do item then
    ## database will complain and error will be thrown.
    ## Just catch it and move along...
  end try

  if theError is empty then
    ## Refresh list
    RefreshToDoList
  end if

  if theError is not empty then
    answer "Error linking person to to-do item:" && theError & "."
  end if
end LinkPersonWithToDo


function NextSequenceForProject pProjectID
  put sqlquery_createObject("todo_items") into theQueryA
  sqlquery_set theQueryA, "select clause", "MAX(sequence)"
  sqlquery_set theQueryA, "conditions", "project_id is :1", pProjectID
  sqlquery_retrieveAsData theQueryA, theData
  if the result is empty then
    return theData + 1
  else
    return 0
  end if
end NextSequenceForProject
