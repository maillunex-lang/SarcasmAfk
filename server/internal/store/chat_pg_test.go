package store_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func TestChatServiceInterfaceMemory(t *testing.T) {
	var svc store.ChatService = store.NewChatHub()
	msg, err := svc.Post("global", "a1", "A", "persist path ready", 2)
	if err != nil {
		t.Fatal(err)
	}
	hist := svc.History("global", 0, 10)
	if len(hist) != 1 || hist[0].ID != msg.ID {
		t.Fatalf("hist %#v", hist)
	}
	svc.DeleteMessage(msg.ID)
	if len(svc.History("global", 0, 10)) != 0 {
		t.Fatal("deleted still visible")
	}
}
