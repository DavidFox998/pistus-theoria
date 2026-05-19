#!/bin/bash
# Compile all machine code across the repository
# Usage: chmod +x compile_all.sh && ./compile_all.sh

set -e

echo "🔨 Compiling all binaries..."
found=0

find . -name "print_*.c" -type f | while read file; do
    dir=$(dirname "$file")
    name=$(basename "$file" .c)
    echo "  Compiling: $name in $dir"
    
    gcc -O2 -static "$file" -o "$dir/$name"
    if [ -f "$dir/$name" ]; then
        sha256sum "$dir/$name" > "$dir/$name.sha256"
        echo "  ✓ $name compiled & SHA locked"
        found=1
    fi
done

if [ $found -eq 1 ]; then
    echo "✓ All binaries compiled successfully"
    git add -A
    git commit -m "Add machine code for binaries, SHA locked" || true
    git push || echo "Push skipped (no remote)"
else
    echo "⚠ No print_*.c files found"
fi
