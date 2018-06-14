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

    var $image = $("#image")
    var $overlay = $("#overlay_image")
    var $good_button = $("#good")
    var $bad_button = $("#bad")
    var $next_button = $("#next")
    var $images_left = $("#images_left")
    var $reviewed_count = $("#reviewed_count")
    var $online = $("#online")
    var $overlay = $("#overlay")
    var $overlay_image = $("#overlay_image")
    var good_overlay_image = "images/good_overlay.png"
    var bad_overlay_image = "images/banned_overlay.png"

    socket.onOpen( ev => console.log("SOCKET OPEN", ev) )
    socket.onError( ev => console.log("SOCKET ERROR", ev) )
    socket.onClose( e => console.log("SOCKET CLOSE", e))

    var chan = socket.channel(`reviewers:${user_token}`, {})
    chan.join()
      .receive( "error", () => console.log("Failed to connect"))
      .receive( "ok",    () => console.log("Connected"))
    chan.onError(e => console.log("Something went wrong", e));
    chan.onClose(e => console.log("Channel closed", e));

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

    var review = function(rating) {
      var poll_next =  $('#auto_next').is(":checked")
      chan.push("submit_review", {review:rating, auto_next:poll_next});
      increment_reviewed();
    }

    var poll_image= function() {
      chan.push("poll_image", {})
    }

    $(document).keydown(function(e) {
      console.log(e.keyCode)
      if (e.keyCode == 38 || e.keyCode == 75) { //up arrow or h
        $good_button.click();
      } else if (e.keyCode == 40 || e.keyCode == 74) { // down arrow or j
        $bad_button.click();
      } else if (e.keyCode == 39 || e.keyCode == 78) { // right arrow  or n
        $next_button.click();
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
    });

    $bad_button.click(function() {
      show_overlay_image(bad_overlay_image);
      review("bad");
    });

    $next_button.click(function() { poll_image(); });

    poll_image();
  }
}

$( () => App.init() )

export default App
