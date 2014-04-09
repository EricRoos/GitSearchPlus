# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


$ ->
  $("a[data-remote]").on "ajax:error", (evt,data,status,xhr) ->
    alert xhr

  $("#query_form").bind "ajax:beforeSend", (evt,data,status,xhr) ->
    $("#loader").show()
    $("#overlay").show()

  $("#query_form").bind "ajax:success", (evt,data,status,xhr) ->
    $("#display").html(data.html_content)
    $("#loader").hide()
    $("#overlay").hide()
$ ->
  $("#query_form").bind "ajax:error", (evt,data,status,xhr) ->
    $("#display").html(xhr)
$ ->
  $("#input_field").bind "keyup", (event) ->
    alert "hello" if event.keyCode == 13

