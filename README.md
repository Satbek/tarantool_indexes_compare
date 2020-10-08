# TREE and HASH tarantool indexes comparing

It uses yandex tank and with pandora loader.

# How to run tests

* build go binary file
    ```bash
    GOOS=linux GOARCH=amd64 go build gun.go
    ```
* generate ammo
    
    There are two types of ammo
     * sequential
        ```json
       {"Type":"hash","Method":"replace","Params":[["pk1","name1","some data"]]}
        ```
        to generate:
        ```bash
       tarantool generate_sequence_ammo.lua
        ```
     * uuid
        ```json
        {"Type":"tree","Method":"replace","Params":[["21aedd24-98a7-4db6-af6e-59232c2e99bd","b5edb23a-0b7b-498e-bc08-a6d8e8da5119","some data"]]}
        ```
        to generate:
        ```bash
        tarantool generate_uuid_ammo.lua
        ```
     It creates ``.txt`` ammo files with 300,000 json records
* start tarantool instances
    ```bash
    tarantool app_hash.lua
    tarantool app_tree.lua
    ```
* modify gun.yaml config
    ```yaml
      pools:
        - id: load_test
          gun:
            type: gun
            target:
               tree: host.docker.internal:3301 #change for localhost:3301 if you use linux
               hash: host.docker.internal:3302 #change for localhost:3302 if you use linux
          ammo:
            type: tarantool_call_provider
            source:
              type: file
              path: ./get_by_secondary_hash.txt #change to necessary ammo file
          result:
            type: phout
            destination: ./phout.log
          rps: #change load params here (by default it runs constant load at 1500 rps for 3 minutes)
            type: const
            ops: 1500
            duration: 3m
          startup:
            type: once
            times: 50 #change workers count here
    ```
* run load test
    ```bash
    docker run -v $(pwd):/var/loadtest           -v $SSH_AUTH_SOCK:/ssh-agent         -e SSH_AUTH_SOCK=/ssh-agent          --net host                           -it direvius/yandex-tank
    ```