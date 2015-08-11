'use strict';

$(function() {

  function getData(){
    $.ajax({
      type: "GET",
      dataType: 'json',
      url: $('#table').data('url'),
    })
    .done(function(data) {
        $('#table').dataTable( {
 //         "serverSide": true,
          "scrollY": "300px",
          "scrollCollapse": true,
          "scroller": {
            loadingIndicator: true
        },
          "order": [[ 1, "asc" ]],
          "aaData": data.aaData,
          "aoColumns": data.aoColumns
        });
    })
    .fail(function() {
        alert( "error occured" );
    });
  }

  getData();

});