#!/bin/bash

USER=user1 nix run 'home-manager' -- --flake . build
