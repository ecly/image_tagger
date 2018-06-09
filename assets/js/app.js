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

    var $image    = $("#image")
    var $good_button  = $("#good")
    var $bad_button  = $("#bad")

    socket.onOpen( ev => console.log("SOCKET OPEN", ev) )
    socket.onError( ev => console.log("SOCKET ERROR", ev) )
    socket.onClose( e => console.log("SOCKET CLOSE", e))

    var chan = socket.channel(`room:${user_token}`, {})
    chan.join()
      .receive( "error", () => console.log("Failed to connect"))
      .receive( "ok",    () => console.log("Connected"))
    chan.onError(e => console.log("Something went wrong", e))
    chan.onClose(e => console.log("Channel closed", e))

    chan.on("new_image", msg => {
      $image.attr("src", msg["url"]);
    })

    var good_button_click = function() {
      chan.push("submit_review", {review:"good"})
    }

    var bad_button_click = function() {
      chan.push("submit_review", {review:"bad"})
    }

    $(document).keydown(function(e) {
      if (e.keyCode == 38) { //upwards arrow click
        good_button_click();
        // chan.push("new:msg", {image: $image.attr("src"), rating: "good"})
      } else if (e.keyCode == 40) { //downwards arrow click
        bad_button_click();
      }
    })

    $good_button.click(function() {
      good_button_click();
    });

    $bad_button.click(function() {
      bad_button_click();
    });

    chan.push("poll_image", "filler_msg")
  }
}

$( () => App.init() )

export default App
