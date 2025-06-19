// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Progress bar disabled

// Hook for auto-dismissing flash messages
let Hooks = {}
Hooks.AutoDismissFlash = {
  mounted() {
    // Auto-dismiss the flash message after 10 seconds
    this.timer = setTimeout(() => {
      this.pushEvent("lv:clear-flash", {key: this.el.id.replace("flash-", "")})
      this.el.style.transition = "opacity 0.5s ease-out"
      this.el.style.opacity = "0"
      setTimeout(() => {
        this.el.style.display = "none"
      }, 500)
    }, 10000)
  },
  destroyed() {
    // Clear the timer if the element is destroyed before 10 seconds
    if (this.timer) {
      clearTimeout(this.timer)
    }
  }
}


// Helper function to get all cookies
function getCookies() {
  const cookies = {}
  document.cookie.split(';').forEach(cookie => {
    const [name, value] = cookie.trim().split('=')
    if (name && value) {
      cookies[name] = decodeURIComponent(value)
    }
  })
  return cookies
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: () => ({
    _csrf_token: csrfToken,
    ...getCookies()
  }),
  hooks: Hooks
})

// Handle copy to clipboard event
window.addEventListener("phx:copy_to_clipboard", (e) => {
  if(navigator.clipboard) {
    navigator.clipboard.writeText(e.detail.text).then(() => {
      // You could show a toast notification here
      console.log("Copied to clipboard:", e.detail.text)
    }).catch(err => {
      console.error("Failed to copy:", err)
    })
  }
})

// Handle setting cookies
window.addEventListener("phx:set_cookie", (e) => {
  const { name, value, max_age } = e.detail
  const expires = new Date(Date.now() + max_age * 1000).toUTCString()
  document.cookie = `${name}=${encodeURIComponent(value)}; expires=${expires}; path=/; SameSite=Lax`
  console.log("Cookie set:", name, value)
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

