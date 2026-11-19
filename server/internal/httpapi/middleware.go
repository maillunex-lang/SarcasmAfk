package httpapi

import (
	"log"
	"net/http"
	"sync/atomic"
	"time"
)

// Metrics is a process-local request counter set (T-093/T-094).
type Metrics struct {
	Requests   atomic.Uint64
	Errors     atomic.Uint64
	StartedUnix int64
}

func NewMetrics() *Metrics {
	return &Metrics{StartedUnix: time.Now().Unix()}
}

func (m *Metrics) Snapshot() map[string]any {
	return map[string]any{
		"requests":     m.Requests.Load(),
		"errors":       m.Errors.Load(),
		"started_unix": m.StartedUnix,
		"uptime_sec":   time.Now().Unix() - m.StartedUnix,
	}
}

type statusWriter struct {
	http.ResponseWriter
	code int
}

func (w *statusWriter) WriteHeader(code int) {
	w.code = code
	w.ResponseWriter.WriteHeader(code)
}

func withLogging(m *Metrics, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		sw := &statusWriter{ResponseWriter: w, code: 200}
		next.ServeHTTP(sw, r)
		if m != nil {
			m.Requests.Add(1)
			if sw.code >= 400 {
				m.Errors.Add(1)
			}
		}
		log.Printf("%s %s -> %d %s", r.Method, r.URL.Path, sw.code, time.Since(start).Truncate(time.Microsecond))
	})
}
