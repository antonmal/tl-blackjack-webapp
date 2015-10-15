$(document).ready(function(){

  playerHit(); 
  playerStay();
  dealerHit();

});


function dealerHit() {
  // If dealer is hitting, dealer-hit-button is displayed
  // In this case, refresh the page every 1.5 seconds
  //   to simulate dealer hitting and show new cards one by one

  if ( $('#dealer-hit-button').length ) {
    ajaxDealerHit();
  };

  $(document).ajaxSuccess(function() {
    if ( $('#dealer-hit-button').length ) {
      ajaxDealerHit();
    };
  });
}

function ajaxDealerHit() {
  setTimeout(function(){
    $.ajax({
      url: '/dealer/hit'
    }).done(function(response){
      $('#game').replaceWith(response);
    });
  }, 1500);
}

function playerHit() {
  $(document).on('click', '#hit-button', function(){
    $.ajax({
      url: '/player/hit'
    }).done(function(response){
      $('#game').replaceWith(response);
    });
    return false;
  });
}

function playerStay() {
  $(document).on('click', '#stay-button', function(){
    $.ajax({
      url: '/dealer'
    }).done(function(response){
      $('#game').replaceWith(response);
    });
    return false;
  });
}

