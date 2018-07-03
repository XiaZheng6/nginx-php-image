#!/bin/bash
docker run --name socket -p 16890:80 -p 2051:2051 -p 2050:2050 -d neon/socket
