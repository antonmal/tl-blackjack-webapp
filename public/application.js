$(document).ready(function(){

  // If dealer is hitting, dealer-hit-button is displayed
  // In this case, refresh the page every 1.5 seconds
  //   to simulate dealer hitting and show new cards one by one
  if ($('#dealer-hit-button').length > 0) {
    setTimeout(function(){
      $('#game').load('/dealer/hit');
    }, 1500);
  };

  $('#hit-button').click(function(){
    $('#game').load('/player/hit');
    return false;
  });

  $('stay-button').click(function(){
    $('#game').load('/dealer');
    return false;
  });

});