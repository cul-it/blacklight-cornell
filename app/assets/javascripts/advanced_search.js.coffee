$(document).ready ->
  $('body.blacklight-advanced-index #q').focus()

  $('#add-row').click ->
    newRow = $('.input_row:last').clone()

    # Find all elements in the clone that have an id, and iterate using each()
    newRow.find('[id]').each ->
      # Get the number at the end of the id, increment it, and replace the old id
      newID = $(this).attr('id').replace(/\d+$/, (str) ->
        return parseInt(str) + 1
      )
      $(this).attr('id', newID)

    # Do the same for the for" attributes
    newRow.find('[for]').each ->
      # Perform the same replace as above
      newFor = $(this).attr('for').replace(/\d+$/, (str) ->
        return parseInt(str) + 1
      )
      $(this).attr('for', newFor)

    newRow.find('input').each ->
      # Clear any populated text input
      if $(this).attr('type') == 'text'
        $(this).val('')
      # we want between row operator to default to AND
      # -- we also want to increment the neme, otherwise values will be overwritten
      if $(this).attr('type') == 'radio'
        incrementedName = $(this).attr('name').replace(/\[(\d+)\]$/, (match, p1) ->
          increment = parseInt(p1) + 1
          return '[' + increment + ']'
        )
        $(this).attr('name', incrementedName)

        if $(this).val() != 'AND'
          $(this).attr('checked', false)
        else
          $(this).attr('checked', true)

    newRow.appendTo('.query_zone')
    return false
