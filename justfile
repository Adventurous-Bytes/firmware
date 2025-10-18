import 'sbc/config.just'
import 'embedded/config.just'

# Default recipe - show available commands
default:
    @just --list

# Quick development commands
ping:
    echo 'Pong!'
