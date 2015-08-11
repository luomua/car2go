'use strict';

$(function() {

    var chartColors = [
    { // blue
        fillColor: "rgba(151,187,205,0.2)",
        strokeColor: "rgba(151,187,205,1)",
        pointColor: "rgba(151,187,205,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(151,187,205,0.8)"
    },
    { // light grey
        fillColor: "rgba(220,220,220,0.2)",
        strokeColor: "rgba(220,220,220,1)",
        pointColor: "rgba(220,220,220,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,0.8)"
    },
    { // red
        fillColor: "rgba(247,70,74,0.2)",
        strokeColor: "rgba(247,70,74,1)",
        pointColor: "rgba(247,70,74,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(247,70,74,0.8)"
    },
    { // green
        fillColor: "rgba(70,191,189,0.2)",
        strokeColor: "rgba(70,191,189,1)",
        pointColor: "rgba(70,191,189,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(70,191,189,0.8)"
    },
    { // yellow
        fillColor: "rgba(253,180,92,0.2)",
        strokeColor: "rgba(253,180,92,1)",
        pointColor: "rgba(253,180,92,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(253,180,92,0.8)"
    },
    { // grey
        fillColor: "rgba(148,159,177,0.2)",
        strokeColor: "rgba(148,159,177,1)",
        pointColor: "rgba(148,159,177,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(148,159,177,0.8)"
    },
    { // dark grey
        fillColor: "rgba(77,83,96,0.2)",
        strokeColor: "rgba(77,83,96,1)",
        pointColor: "rgba(77,83,96,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(77,83,96,1)"
    }
    ],
    stepWidth = 5,
    steps = 6,
    start = 0,
    wr = 1,
    chartData = {};

  function drawChart() {
    var canv = $('#chart');
    var ctx = canv.get(0).getContext("2d");
    var container = canv.parent();

    var $container = $(container);

    if ($container.width() >= (wr * 50)) {
        canv.attr('width', (wr * 50));
    } else if ($container.width() <= (wr * 10)) {
        canv.attr('width', (wr * 10)); 
    } else {
        canv.attr('width', $container.width());  
    }
    
    if (window.innerHeight <= 360) {
        canv.attr('height', window.innerHeight);
    } else {
        canv.attr('height', 360);
    }

    var chart = new Chart(ctx).Bar(chartData, {
//        animation: false,
        scaleOverride: true,
        scaleSteps: steps,
        scaleStepWidth: stepWidth,
        scaleStartValue: start,
        scaleLabel: function (value) {
                return value.value + '天';
               }
    });
  }

  function getData(){
    $.ajax({
      type: "GET",
      dataType: 'json',
      url: $('#chart').data('url'),
    })
    .done(function(data) {
        var i = Math.floor((Math.random() * 7));
        chartData = {
            labels: data.labels,
            datasets: [
                {
                    fillColor: chartColors[i].fillColor,
                    strokeColor: chartColors[i].strokeColor,
                    pointColor: chartColors[i].pointColor,
                    pointStrokeColor: chartColors[i].pointStrokeColor,
                    pointHighlightFill: chartColors[i].pointHighlightFill,
                    pointHighlightStroke: chartColors[i].pointHighlightStroke,
                    data: data.data
                }
            ]
        };

        var max = Math.max.apply(Math, chartData.datasets[0].data);
        var min = Math.min.apply(Math, chartData.datasets[0].data.filter(Number));
        stepWidth = Math.ceil(max / steps);
        if ((min / stepWidth) > 1.5 ) {
           start = (Math.round(min / stepWidth) - 0.5) * stepWidth;
        };
        stepWidth = Math.ceil((max - start) / steps);

        wr = chartData.labels.length;

        drawChart();
    })
    .fail(function() {
        alert( "error occured" );
    });
  }

  getData();

});