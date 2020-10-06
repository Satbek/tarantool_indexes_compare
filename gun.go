package main

import (
	"github.com/spf13/afero"
	"github.com/tarantool/go-tarantool"
	"github.com/yandex/pandora/cli"
	"github.com/yandex/pandora/core"
	"github.com/yandex/pandora/core/aggregator/netsample"
	coreimport "github.com/yandex/pandora/core/import"
	"github.com/yandex/pandora/core/register"
	"log"
	"time"
)

type Ammo struct {
	Method   string
	Type string
	Params   []interface{}
}

func customAmmoProvider() core.Ammo {
	return &Ammo{}
}

type GunConfig struct {
	Target map[string]string `validate:"required"`
}

type Gun struct {
	connTree *tarantool.Connection
	connHash *tarantool.Connection
	conf   GunConfig
	aggr   core.Aggregator
}

func NewGun(conf GunConfig) *Gun {
	return &Gun{
		conf: conf,
	}
}

func (g *Gun) Bind(aggr core.Aggregator, deps core.GunDeps) error {
	opts := tarantool.Opts{
		User: "guest",
	}
	connTree, err := tarantool.Connect(
		g.conf.Target["tree"],
		opts,
	)
	if err != nil {
		log.Fatalf("Error: %s", err)
	}
	connHash, err := tarantool.Connect(
		g.conf.Target["hash"],
		opts,
	)
	if err != nil {
		log.Fatalf("Error: %s", err)
	}
	g.connTree = connTree
	g.connHash = connHash
	g.aggr = aggr

	return nil
}

func (g *Gun) Shoot(coreAmmo core.Ammo) {
	ammo := coreAmmo.(*Ammo)
	sample := netsample.Acquire(ammo.Method)

	code := 200
	var err error
	startTime := time.Now()
	switch ammo.Type {
	case "tree":
		_, err = g.connTree.Call(ammo.Method, ammo.Params)
	case "hash":
		_, err = g.connHash.Call(ammo.Method, ammo.Params)
	}

	sample.SetLatency(time.Since(startTime))
	if err != nil {
		log.Printf("Error %s task: %s", ammo.Method, err)
		code = 500
	}

	defer func() {
		sample.SetProtoCode(code)
		sample.AddTag(ammo.Type)
		g.aggr.Report(sample)
	}()
}

func main() {
	fs := afero.NewOsFs()
	coreimport.Import(fs)

	coreimport.RegisterCustomJSONProvider("tarantool_call_provider", customAmmoProvider)
	register.Gun("gun", NewGun, func() GunConfig {
		return GunConfig{
			Target: map[string]string{
				"tree": "host.docker.internal:3301",
				"hash": "host.docker.internal:3302",
			},
		}
	})
	cli.Run()
}
