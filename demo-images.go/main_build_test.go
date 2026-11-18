package main

import (
	"net/http/httptest"
	"runtime"
	"strings"
	"testing"
)

func TestCaseInsensitiveContains(t *testing.T) {
	if !CaseInsensitiveContains("CuRL/8.0", "curl") || CaseInsensitiveContains("browser", "curl") {
		t.Fatal("case-insensitive matching failed")
	}
}

func TestFormatRequest(t *testing.T) {
	req := httptest.NewRequest("GET", "http://demo.local/echo?q=100%25", nil)
	req.Header.Set("X-Demo", "test")
	text := formatRequest(req)
	for _, want := range []string{"GET http://demo.local/echo?q=100%25 HTTP/1.1", "Host: demo.local", "x-demo: test"} {
		if !strings.Contains(text, want) {
			t.Errorf("request is missing %q: %s", want, text)
		}
	}
}

func TestVersionPlatform(t *testing.T) {
	rec := httptest.NewRecorder()
	route_showVersion(rec, httptest.NewRequest("GET", "/version", nil))
	if !strings.Contains(rec.Body.String(), "platform: "+runtime.GOOS+"/"+runtime.GOARCH) {
		t.Fatalf("missing target platform: %s", rec.Body.String())
	}
}

func TestHTMLPercentSigns(t *testing.T) {
	savedMessage := message
	message = "100% ready; literal %s"
	defer func() { message = savedMessage }()
	req := httptest.NewRequest("GET", "/", nil)
	req.Header.Set("User-Agent", "Mozilla/5.0")
	rec := httptest.NewRecorder()
	route_index(rec, req)
	if !strings.Contains(rec.Body.String(), message) || strings.Contains(rec.Body.String(), "%!") {
		t.Fatalf("response treated percent signs as formatting: %s", rec.Body.String())
	}
}

func TestPing(t *testing.T) {
	rec := httptest.NewRecorder()
	req := httptest.NewRequest("GET", "/ping", nil)
	route_ping(rec, req)
	if rec.Code != 200 || !strings.Contains(rec.Body.String(), req.RemoteAddr) {
		t.Fatalf("unexpected ping response: %d %s", rec.Code, rec.Body.String())
	}
}
