#!/bin/bash

# Build both escript binaries for ElixirNoDeps

echo "Building present binary..."
mix escript.build

echo "Building remote_present binary..."
MIX_ESCRIPT_NAME=remote_present mix escript.build

echo ""
echo "✅ Both binaries built successfully!"
echo "   • present - Terminal presentation tool"
echo "   • remote_present - Remote control presentation tool"
echo ""
echo "Test with:"
echo "   ./present --help"
echo "   ./remote_present --help"