#!/bin/bash

set -e

hostnamectl set-hostname ansible01

apt-get update
apt-get install -y ansible