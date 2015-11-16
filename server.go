package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"

	"github.com/sebest/xff"
)

type output struct {
	Addr string `json:"addr"`
}

var (
	port *int
)

func init() {
	port = flag.Int("port", 80, "the port to listen on")
	flag.Parse()
}

func handler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		data, err := json.Marshal(output{
			Addr: r.RemoteAddr,
		})

		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		if _, err := w.Write(data); err != nil {
			log.Println(err)
		}
	})
}

func main() {
	server := xff.Handler(handler())
	addr := fmt.Sprintf(":%d", *port)

	if err := http.ListenAndServe(addr, server); err != nil {
		log.Fatal(err)
	}
}
