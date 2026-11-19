package store_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func TestGuildDonateAndQuests(t *testing.T) {
	h := store.NewGuildHub()
	g, err := h.Create("acc1", "Казна", "KZN", "")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := h.Join("acc2", g.ID); err != nil {
		t.Fatal(err)
	}
	g2, err := h.Donate("acc2", 200)
	if err != nil {
		t.Fatal(err)
	}
	if g2.VaultSoft < 200 {
		t.Fatalf("vault %d", g2.VaultSoft)
	}
	quests, err := h.Quests("acc2")
	if err != nil || len(quests) == 0 {
		t.Fatalf("quests %v %v", quests, err)
	}
	board, err := h.MemberBoard("acc1")
	if err != nil || len(board) != 2 {
		t.Fatalf("board %v %v", board, err)
	}
}

func TestChatMuteBlocksPost(t *testing.T) {
	c := store.NewChatHub()
	c.MuteAccount("bad", 60)
	_, err := c.Post("global", "bad", "x", "hello", 1)
	if err != store.ErrMuted {
		t.Fatalf("got %v", err)
	}
	c.UnmuteAccount("bad")
	if _, err := c.Post("global", "bad", "x", "hello", 1); err != nil {
		t.Fatal(err)
	}
}
