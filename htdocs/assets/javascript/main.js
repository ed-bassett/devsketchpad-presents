var pageData;
var pageName = document.URL;

var docParts = {};

$(document).ready(function(){
  $.ajaxSetup ({
    cache: false
  });
  try{initialize();} catch(e){}

  //var gap = ( $(window).height() - $('#content').offset().top - 70 );
  //$('#content').css( "height" , gap );

  set_click();
  $('.choose').live('click', function(event){
    event.preventDefault();
    $.get($(this).attr('href'), function() {
      $('#content').load(pageName + ' #content>*');
      //$('#page_gifts_wrapper').load(pageName + ' #page_gifts');
    });
  });
  $('.choice .button').live('click', function(event){
    event.preventDefault();
    $.get($(this).attr('href'), function() {
      $('#content_wrapper').load('/index.html #content');
    });
  });
  $('#like').live('click', function(){
    $('#preference_form .dependant').fadeToggle();
  });

  $('.controller').live('click', function(){
    var controls = $(this).attr('class').match(/controls_(\S+)/)[1]
    if ( controls )
    {
      $(document).find('.depends_' + controls).slideToggle();
      $(this).toggleClass('collapsed');
    }
  });
});

function set_click(message) {
  var activeSubmit;
  $('#all').click(function(e){
    var $link = $(e.target);
    if( $link.is('a[class*="affects_"]') ) {
      if( $link.attr('href') ) {
        e.preventDefault();
        var affects = $link.attr('class').match(/affects_(\S+)/)[1];
        if ( affects === 'parent' ) {
          affects = $link.parents('.frame').attr('id');
        }
        if( $link.is('a[class*="loads_"]') ) {
          loadPart(
            $link.attr('href'),
            $link.attr('class').match(/loads_(\S+)/)[1],
            affects,
            function(){showPopup();}
          );
        } else {
          loadPart(
            $link.attr('href'),
            affects,
            affects
          );
        }
      }
    } else if ( $(e.target).is('input') ) {
      activeSubmit=$(e.target);
    }
  });
  $('#all').submit(function(e){
    var form = $(e.target);
    if( form.is('form[class*="affects_"]') ) {
      e.preventDefault();
      //var submit = form.find('input:submit:focus') || activeSubmit;
      var submit = activeSubmit;
      console.log('submit: '+activeSubmit.attr('name'));
      var affects = form.attr('class').match(/affects_(\S+)/)[1];
      if ( affects === 'parent' ) {
        affects = form.parents('.frame').attr('id');
      }
      if( form.is('form[class*="loads_"]') ) {
        console.log('loads');
        loadPart(
          e.target.action + '?' + $(e.target).serialize() + '&' + submit.attr('name') + '=' + encodeURI(submit.attr('value')),
          form.attr('class').match(/loads_(\S+)/)[1],
          affects
        );
      } else {
        loadPart(
          e.target.action + '?' + $(e.target).serialize() + '&' + submit.attr('name') + '=' + encodeURI(submit.attr('value')),
          affects,
          affects
        );
      }
      return false;
    }
    return true;
  });
}

function showPopup() {
  $('#cover').fadeIn();

  var closeButton = $('<span id="close_popup" class="button">Close</span>');
  closeButton.click(function(){ hidePopup()});
  $('#popup').append(closeButton);
  var gap = ( $(window).height() - $('#popup').height() ) /2;
  $('#popup').css( "margin-top" , gap );
  $('#popup').fadeIn('slow');

  $('#body').fadeTo('normal', .3);
}

function hidePopup() {
  $('#cover').fadeOut();
  $('#popup').fadeOut(function(){
    $('#popup_content').children().remove();
    $('#popup').find('#close_popup').remove();
  });
//THIS IS A HACK, FIX IT
  loadPart(
    '/',
    'content',
    'content'
  );

  $('#body').fadeTo('normal', 1);
}

function loadPart (location, load_section, fill_section, done) {
  //document.location = document.location + '#test';
  //document.location = '#'+location.match(/http:\/\/[^\/]*\/(.*)/)[1];
  //docParts[pageName + ' #' + section] = $('#' + section).html();
  pageName=location;
  //$('#' + id).fadeTo('fast', .5);
  if( docParts[location + ' #' + load_section] != null ) {
    console.log('Cached');
    $('#' + section).empty();
    $('#' + section).prepend(docParts[location + ' #' + fill_section]);
    {
      $('#'+load_section+' div[class*="run_"]').each(function () {
        var funcName = this.className.match(/run_(\S+)/)[1];
        window[funcName]();
      });
    }
  } else {
    console.log(fill_section);

    $('#' + fill_section).load(
      location + ' #' + load_section + '> *', function(){
        if ( typeof done != "undefined" ) {
          done();
        }
      });
      //function(data){
//        docParts[location + ' #' + section] = $('#' + section).contents();
        //$.getJSON(
        //  location,
        //  {jquery: true},
        //  function(data){
        //    pageData=data;
        //    $('#'+section+' div[class*="run_"]').each(function () {
        //      var funcName = this.className.match(/run_(\S+)/)[1];
        //      window[funcName]();
        //    });
        //});
        //$('#' + id).fadeTo('fast', 1);
    //});
  }
}

