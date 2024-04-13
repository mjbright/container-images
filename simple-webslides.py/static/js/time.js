
// Get time, keep updating to <div id="time" />

// See: https://www.w3schools.com/js/js_date_methods.asp for date functions

function pad2Digit(i) {
  if (i < 10) { i = "0" + i; }
  return i;
}

function startDateTime() {
  var today = new Date();

  // add a zero in front of numbers<10
  var h = pad2Digit( today.getHours() );
  var m = pad2Digit( today.getMinutes() );
  var s = pad2Digit( today.getSeconds() );
  var time = h + ":" + m + ":" + s;

  var Y = today.getFullYear();
  var M = pad2Digit( today.getMonth() + 1 );
  var D = pad2Digit( today.getDate() );
  var date = Y + "-" + M + "-" + D;

  document.getElementById('date_time').innerHTML = date + ' ' + time;

  t = setTimeout(function() { startDateTime() }, 500); // Re-run every 500 msec
}

function startTime() {
  var today = new Date();

  // add a zero in front of numbers<10
  var h = pad2Digit( today.getHours() );
  var m = pad2Digit( today.getMinutes() );
  var s = pad2Digit( today.getSeconds() );
  var time = h + ":" + m + ":" + s;
  document.getElementById('time').innerHTML = time

  t = setTimeout(function() { startTime() }, 500); // Re-run every 500 msec
}

//startTime();
startDateTime();

