#!/bin/bash

function start_bot() {
	ruby main.rb
	return 0
}

while true; do
	start_bot;
done
