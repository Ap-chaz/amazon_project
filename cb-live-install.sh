#!/bin/bash
set -e

# ===== Colors & Emoji =====
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "🚀 ${CYAN}Installing cb-live (Crossberry Live Server)${RESET}"
echo -e "👤 Author: ${YELLOW}Crossberry${RESET}"
echo -e "🌐 Website: ${GREEN}https://crossberry.pages.dev${RESET}"
echo

# ===== Check Go =====
if ! command -v go >/dev/null 2>&1; then
    echo -e "❌ ${RED}Go not found. Please install Go first.${RESET}"
    exit 1
fi
echo -e "✅ ${GREEN}Go already installed${RESET}"

# ===== Paths =====
INSTALL_DIR="$HOME/cb-live"
BIN_DIR="/data/data/com.termux/files/usr/bin"

mkdir -p "$BIN_DIR"

# ===== Setup folder =====
echo -e "🔹 ${CYAN}Creating cb-live directory...${RESET}"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# ===== Go source =====
cat > main.go <<'EOF'
package main

import (
	"fmt"
	"io/fs"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
	"github.com/gorilla/websocket"
)

var (
	upgrader   = websocket.Upgrader{}
	clients    = make(map[*websocket.Conn]bool)
	clientsMux sync.Mutex
)

// ===== Emoji & Color =====
const (
	RESET  = "\033[0m"
	RED    = "\033[1;31m"
	GREEN  = "\033[1;32m"
	YELLOW = "\033[1;33m"
	CYAN   = "\033[1;36m"
)

const (
	SuccessEmoji = "✅"
	ReloadEmoji  = "🔄"
	ErrorEmoji   = "❌"
	InfoEmoji    = "ℹ️"
	ServerEmoji  = "🚀"
)

var spinner = []string{"⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"}

func animateMessage(msg string) {
	for i := 0; i < 10; i++ {
		fmt.Printf("\r%s %s %s", spinner[i%len(spinner)], msg, RESET)
		time.Sleep(80 * time.Millisecond)
	}
	fmt.Print("\r")
}

func logReload(file string) {
	fmt.Printf("%s %s Reload triggered for: %s%s\n", ReloadEmoji, CYAN, file, RESET)
}

func logError(err error) {
	fmt.Printf("%s %s %s%s\n", ErrorEmoji, RED, err, RESET)
}

func logInfo(msg string) {
	fmt.Printf("%s %s%s\n", InfoEmoji, YELLOW, msg)
}

func logSuccess(msg string) {
	fmt.Printf("%s %s%s\n", SuccessEmoji, GREEN, msg)
}

func logServerStart(dir string, port int) {
	fmt.Printf("%s %s Serving '%s' at http://localhost:%d%s\n", ServerEmoji, GREEN, dir, port, RESET)
}

// ===== Broadcast reload =====
func broadcastReload() {
	clientsMux.Lock()
	defer clientsMux.Unlock()
	for c := range clients {
		c.WriteMessage(websocket.TextMessage, []byte("reload"))
	}
}

func main() {
	args := os.Args[1:]
	port := 7050
	dir := "."
	mode := "static"

	if len(args) > 0 {
		if args[0] == "-help" {
			fmt.Println("Usage: cb-live [directory] [mode] [port]")
			fmt.Println("Modes: static (default), php")
			fmt.Println("Examples:")
			fmt.Println("  cb-live                  Serve current directory")
			fmt.Println("  cb-live ~/myapp           Serve specific directory")
			fmt.Println("  cb-live ~/myapp 8080      Serve with custom port")
			fmt.Println("  cb-live ~/myapp php       Serve PHP files")
			return
		}
		dir = args[0]
	}

	if len(args) > 1 {
		mode = strings.ToLower(args[1])
	}

	if len(args) > 2 {
		if p, err := strconv.Atoi(args[2]); err == nil {
			port = p
		}
	}

	if _, err := os.Stat(dir); os.IsNotExist(err) {
		fmt.Println("❌ Directory does not exist:", dir)
		return
	}

	if mode == "php" {
		fmt.Printf("🚀 Starting PHP server at http://localhost:%d\n", port)
		cmd := exec.Command("php", "-S", fmt.Sprintf("localhost:%d", port), "-t", dir)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Run()
		return
	}

	// ===== File watcher =====
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		panic(err)
	}
	defer watcher.Close()

	go func() {
		for {
			select {
			case ev := <-watcher.Events:
				if ev.Op&(fsnotify.Write|fsnotify.Create|fsnotify.Remove|fsnotify.Rename) != 0 {
					logReload(ev.Name)
					broadcastReload()
				}
			case err := <-watcher.Errors:
				logError(err)
			}
		}
	}()

	filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if d.IsDir() {
			watcher.Add(path)
		}
		return nil
	})

	// ===== WebSocket endpoint =====
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		upgrader.CheckOrigin = func(r *http.Request) bool { return true }
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			return
		}
		clientsMux.Lock()
		clients[conn] = true
		clientsMux.Unlock()
	})

	// ===== File server =====
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		path := filepath.Join(dir, r.URL.Path)
		info, err := os.Stat(path)
		if err == nil && info.IsDir() {
			path = filepath.Join(path, "index.html")
		}

		if strings.HasSuffix(path, ".html") {
			data, err := os.ReadFile(path)
			if err != nil {
				http.NotFound(w, r)
				logError(fmt.Errorf("file not found: %s", path))
				return
			}
			script := `<script>
			let ws = new WebSocket("ws://" + location.host + "/ws");
			ws.onmessage = (msg) => {
				if (msg.data === "reload") {
					console.log("🔄 Reload triggered");
					location.reload();
					document.querySelectorAll("iframe").forEach(f => f.src=f.src);
				}
			};
			</script>`
			html := strings.Replace(string(data), "</body>", script+"</body>", 1)
			if html == string(data) {
				html += script
			}
			w.Header().Set("Content-Type", "text/html")
			w.Write([]byte(html))
		} else {
			http.ServeFile(w, r, path)
		}
	})

	logServerStart(dir, port)
	http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
}
EOF

# ===== Init module & dependencies =====
echo -e "🔹 ${CYAN}Initializing Go module...${RESET}"
go mod init cb-live >/dev/null 2>&1 || true
go get github.com/fsnotify/fsnotify github.com/gorilla/websocket >/dev/null 2>&1

# ===== Build binary =====
echo -e "🔹 ${CYAN}Building cb-live...${RESET}"
go build -o cb-live

# ===== Move to Termux global bin =====
mv -f cb-live "$BIN_DIR/"

echo
echo -e "✅ ${GREEN}cb-live installed successfully 🎉${RESET}"
echo -e "Usage examples:"
echo -e "  cb-live                  Serve current directory"
echo -e "  cb-live ~/myapp          Serve specific directory"
echo -e "  cb-live ~/myapp 8080     Serve with custom port"
echo -e "  cb-live ~/myapp php      Serve PHP files"
echo -e "  cb-live -help            Show help"
echo -e "👤 Author: Crossberry | 🌐 ${GREEN}https://crossberry.pages.dev${RESET}"
