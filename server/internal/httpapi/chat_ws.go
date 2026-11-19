package httpapi

import (
	"encoding/json"
	"net/http"
	"strings"
	"sync"

	"github.com/gorilla/websocket"
)

var wsUpgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

type wsClient struct {
	conn      *websocket.Conn
	accountID string
	channels  map[string]bool
}

type wsHub struct {
	mu      sync.Mutex
	clients map[*wsClient]bool
}

func newWSHub() *wsHub {
	return &wsHub{clients: map[*wsClient]bool{}}
}

func (h *wsHub) add(c *wsClient) {
	h.mu.Lock()
	h.clients[c] = true
	h.mu.Unlock()
}

func (h *wsHub) remove(c *wsClient) {
	h.mu.Lock()
	delete(h.clients, c)
	h.mu.Unlock()
}

func (h *wsHub) broadcast(channel string, payload any) {
	b, err := json.Marshal(payload)
	if err != nil {
		return
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	for c := range h.clients {
		if c.channels[channel] || c.channels["*"] {
			_ = c.conn.WriteMessage(websocket.TextMessage, b)
		}
	}
}

func (s *Server) chatWS(w http.ResponseWriter, r *http.Request) {
	tok := bearer(r)
	if tok == "" {
		tok = r.URL.Query().Get("token")
	}
	acc, err := s.Store.AccountByToken(tok)
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "UNAUTHENTICATED")
		return
	}
	conn, err := wsUpgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}
	client := &wsClient{conn: conn, accountID: acc.AccountID, channels: map[string]bool{"global": true}}
	s.WS.add(client)
	defer func() {
		s.WS.remove(client)
		_ = conn.Close()
	}()
	_ = conn.WriteJSON(map[string]any{"ok": true, "type": "hello", "account_id": acc.AccountID})

	for {
		_, data, err := conn.ReadMessage()
		if err != nil {
			return
		}
		var msg struct {
			Type    string `json:"type"`
			Channel string `json:"channel"`
			Text    string `json:"text"`
			Name    string `json:"display_name"`
			Target  string `json:"target_id"` // for dm
		}
		if json.Unmarshal(data, &msg) != nil {
			continue
		}
		switch msg.Type {
		case "subscribe":
			ch := msg.Channel
			if ch == "" {
				ch = "global"
			}
			client.channels[ch] = true
		case "send":
			ch := msg.Channel
			if ch == "" {
				ch = "global"
			}
			if strings.HasPrefix(ch, "dm:") {
				// normalize dm pair
			}
			if msg.Target != "" {
				a, b := acc.AccountID, msg.Target
				if a > b {
					a, b = b, a
				}
				ch = "dm:" + a + ":" + b
			}
			name := msg.Name
			if name == "" {
				name = acc.AccountID
			}
			posted, err := s.Chat.Post(ch, acc.AccountID, name, msg.Text, acc.CommanderXP/100+1)
			if err != nil {
				_ = conn.WriteJSON(map[string]any{"ok": false, "error": "RATE_LIMITED"})
				continue
			}
			payload := map[string]any{"ok": true, "type": "message", "message": posted}
			s.WS.broadcast(ch, payload)
			if ch != "global" {
				_ = conn.WriteJSON(payload)
			}
		}
	}
}
