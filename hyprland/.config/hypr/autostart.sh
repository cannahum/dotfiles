#!/bin/bash

for i in {1..5}; do
  scarlett_sink_id=$(wpctl status | awk '/Sinks:/, /Sources:/' | sed 's/│//g' | grep -i 'Scarlett 2i2' | awk 'NR==1 {print $1}' | tr -d '.')
  if [[ -n "$scarlett_sink_id" ]]; then
    echo "Scarlett sink detected: ID $scarlett_sink_id"
    wpctl set-default "$scarlett_sink_id"
    break
  else
    echo "Scarlett sink not found (attempt $i)..."
    sleep 1
  fi
done

