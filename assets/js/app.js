// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
// import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import {Socket} from "phoenix"
import $ from "jquery"

class App {
  static init(){
    var rand = function() {
      return Math.random().toString(36).substr(2); // remove `0.`
    };
    // Generate a random user_token
    let user_token = rand() + rand();
    let socket = new Socket("/socket", {params: {token: user_token}})
    socket.connect()
    socket.onOpen( ev => console.log("SOCKET OPEN", ev) )
    socket.onError( ev => console.log("SOCKET ERROR", ev) )
    socket.onClose( e => console.log("SOCKET CLOSE", e))

    var $login_body = $("#login_body")
    var $review_body = $("#review_body")
    var $login_error = $("#login_error_image")
    var $login_button = $("#login_button")

    var show_login = function() {
      $review_body.hide();
      $login_body.show();
    }

    var show_review = function(socket) {
      $login_body.hide();
      $review_body.show();
    }

    var hide_login_error = function(){ $login_error.hide() }

    var show_login_error = function(socket) {
      $login_error.show()
      setTimeout(hide_login_error, 2000);
    }

     var hide_overlay = function() {
        $overlay.hide();
        $overlay_image.attr("src", "");
      }
      var show_overlay_image = function(image) {
        $overlay_image.attr("src", image);
        $("#overlay").show();
        setTimeout(hide_overlay, 500);
      }

    $login_button.click(function() {
      var password = $("#password").val();
      var chan = socket.channel(`reviewers:${user_token}`, {password:password})
      chan.join()
        .receive( "error", () => show_login_error())
        .receive( "ok",    () => show_review())
      chan.onError(e => show_login());
      chan.onClose(e => show_login());
      start_review(chan);
    })

     $('#password').keydown(function(e) {
       console.log(e.keyCode);
        if(e.keyCode == 13) {
            $login_button.click();
            return false;
        }
    });

    var start_review = function(chan){
      var $image = $("#image")
      var $good_button = $("#good")
      var $bad_button = $("#bad")
      var $next_button = $("#next")
      var $undo_button = $("#undo")
      var $images_left = $("#images_left")
      var $reviewed_count = $("#reviewed_count")
      var $online = $("#online")
      var $overlay = $("#overlay")
      var $overlay_image = $("#overlay_image")
      var good_overlay_image = "images/good_overlay.png"
      var bad_overlay_image = "images/banned_overlay.png"
      var undo_overlay_image = "images/undo_overlay.png"


      chan.on("new_image", msg => {
        $image.attr("src", msg["url"]);
        if(msg["count"] >= 999){
          $images_left.text("999+");
        } else {
          $images_left.text(msg["count"]);
        }
        $online.text(msg["online"]);
      });

      var increment_reviewed = function() {
        var value = parseInt($reviewed_count.text(), 10) + 1;
        $reviewed_count.text(value);
      }

      var decrement_reviewed = function() {
        var current = parseInt($reviewed_count.text(), 10);
        var new_value = current <= 0 ? 0 : current - 1;
        $reviewed_count.text(new_value);
      }

      var review = function(rating) {
        var poll_next =  $('#auto_next').is(":checked")
        chan.push("submit_review", {review:rating, auto_next:poll_next});
      }

      var poll_image= function() {
        chan.push("poll_image", {})
      }

      $(document).keydown(function(e) {
        if (e.keyCode == 38 || e.keyCode == 75) { //up arrow or h
          $good_button.click();
        } else if (e.keyCode == 40 || e.keyCode == 74) { // down arrow or j
          $bad_button.click();
        } else if (e.keyCode == 39 || e.keyCode == 78) { // right arrow  or n
          $next_button.click();
        } else if (e.keyCode == 37 || e.keyCode == 85) { // left arrow  or u
          $undo_button.click();
        } else {
          return true;
        }
        return false;
      })

     var hide_overlay = function() {
        $overlay.hide();
        $overlay_image.attr("src", "");
      }
      var show_overlay_image = function(image) {
        $overlay_image.attr("src", image);
        $("#overlay").show();
        setTimeout(hide_overlay, 500);
      }

      // we also want to hide overlay when next image has loaded
      image.addEventListener('load', hide_overlay)

      $good_button.click(function() {
        show_overlay_image(good_overlay_image);
        review("good");
        increment_reviewed();
      });

      $bad_button.click(function() {
        show_overlay_image(bad_overlay_image);
        review("bad");
        increment_reviewed();
      });

      $undo_button.click(function() {
        show_overlay_image(undo_overlay_image);
        chan.push("undo", {})
        decrement_reviewed();
      });

      $next_button.click(function() { poll_image(); });

      poll_image();
    }
  }
}

$( App.init() )

export default App
