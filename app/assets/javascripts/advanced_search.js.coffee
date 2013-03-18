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

    # Do the same for "name" and "for" attributes
    newRow.find('[name]').each ->
      # Perform the same replace as above
      newName = $(this).attr('name').replace(/\d+$/, (str) ->
        return parseInt(str) + 1
      )
      $(this).attr('name', newName)

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
      if $(this).attr('type') == 'radio'
        if $(this).val() != 'AND'
          $(this).attr('checked', false)
        else
          $(this).attr('checked', true)

    newRow.appendTo('.query_column')
    return false
