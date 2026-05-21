#!/usr/bin/env bash
# recon.sh — Automated project reconnaissance for security policy generation.
# Run from project root. Outputs structured findings to stdout.

set -euo pipefail

echo "=== Security Policy Reconnaissance ==="
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Directory: $(pwd)"
echo ""

# --- Language & Package Manager Detection ---
echo "## Detected Stack"
declare -a detected_stack=()

[ -f "package.json" ] && detected_stack+=("Node.js/TypeScript")
[ -f "go.mod" ] && detected_stack+=("Go")
[ -f "Cargo.toml" ] && detected_stack+=("Rust")
[ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ] && detected_stack+=("Python")
[ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ] && detected_stack+=("Java/Kotlin")
[ -f "Gemfile" ] && detected_stack+=("Ruby")
ls *.csproj 2>/dev/null | head -1 > /dev/null && detected_stack+=("C#/.NET")
[ -f "composer.json" ] && detected_stack+=("PHP")

if [ ${#detected_stack[@]} -eq 0 ]; then
  echo "- Could not auto-detect stack"
else
  for s in "${detected_stack[@]}"; do echo "- $s"; done
fi
echo ""

# --- Deployment Detection ---
echo "## Deployment Indicators"
[ -f "Dockerfile" ] && echo "- Dockerfile found"
[ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] && echo "- Docker Compose found"
[ -d "k8s" ] || [ -d "kubernetes" ] || [ -d "deploy/k8s" ] && echo "- Kubernetes manifests found"
[ -f "serverless.yml" ] || [ -f "serverless.yaml" ] && echo "- Serverless framework found"
[ -d "terraform" ] || [ -f "main.tf" ] && echo "- Terraform found"
[ -f ".github/workflows/"* ] 2>/dev/null && echo "- GitHub Actions found"
[ -f "Procfile" ] && echo "- Heroku Procfile found"
[ -f "fly.toml" ] && echo "- Fly.io config found"
[ -f "vercel.json" ] && echo "- Vercel config found"
echo ""

# --- Security Config Detection ---
echo "## Existing Security Configuration"
[ -f "SECURITY.md" ] && echo "- SECURITY.md exists (will be backed up)"
[ -f ".gitleaks.toml" ] && echo "- Gitleaks config (.gitleaks.toml)"
[ -f ".pre-commit-config.yaml" ] && echo "- Pre-commit hooks configured"
[ -f ".github/dependabot.yml" ] && echo "- Dependabot configured"
[ -f "CODEOWNERS" ] || [ -f ".github/CODEOWNERS" ] && echo "- CODEOWNERS file present"
[ -f ".snyk" ] && echo "- Snyk config present"
[ -f "trivy.yaml" ] && echo "- Trivy config present"
[ -f ".trivyignore" ] && echo "- Trivy ignore file present"
echo ""

# --- Dependency Counts ---
echo "## Dependencies"
if [ -f "package-lock.json" ]; then
  total=$(cat package-lock.json | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    pkgs = data.get('packages', data.get('dependencies', {}))
    print(len(pkgs))
except: print('unknown')
" 2>/dev/null || echo "unknown")
  echo "- Node.js packages (lockfile): $total"
fi
if [ -f "yarn.lock" ]; then
  total=$(grep -c '^"' yarn.lock 2>/dev/null || echo "unknown")
  echo "- Yarn packages (approx): $total"
fi
if [ -f "go.sum" ]; then
  total=$(wc -l < go.sum | tr -d ' ')
  echo "- Go modules (go.sum lines): $total"
fi
if [ -f "Cargo.lock" ]; then
  total=$(grep -c '^\[\[package\]\]' Cargo.lock 2>/dev/null || echo "unknown")
  echo "- Rust crates: $total"
fi
if [ -f "Pipfile.lock" ] || [ -f "poetry.lock" ]; then
  echo "- Python lockfile present"
fi
echo ""

# --- Exposed Ports / Network ---
echo "## Network Exposure Indicators"
if [ -f "Dockerfile" ]; then
  grep -i "^EXPOSE" Dockerfile 2>/dev/null | while read -r line; do echo "- Dockerfile: $line"; done
fi
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
  compose_file="docker-compose.yml"
  [ -f "docker-compose.yaml" ] && compose_file="docker-compose.yaml"
  grep -A2 "ports:" "$compose_file" 2>/dev/null | grep -E "^\s+-" | while read -r line; do echo "- Compose port: $line"; done
fi
echo ""

# --- Secret Patterns (potential exposure) ---
echo "## Potential Secret Patterns in Code"
echo "(Searching for common patterns — false positives expected)"
# Only search tracked files, skip binary, limit output
patterns='(API_KEY|SECRET_KEY|PRIVATE_KEY|password\s*=\s*["\x27][^\x27"]+|aws_access_key_id|DATABASE_URL\s*=\s*["\x27])'
count=$(grep -rIlE "$patterns" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.rs" --include="*.java" --include="*.rb" --include="*.env.example" --include="*.yaml" --include="*.yml" . 2>/dev/null | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ')
echo "- Files with potential secret patterns: $count"
echo ""

# --- Auth Libraries ---
echo "## Authentication Libraries Detected"
if [ -f "package.json" ]; then
  for lib in passport jsonwebtoken jose next-auth @auth bcrypt argon2 express-session; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in golang.org/x/crypto github.com/golang-jwt github.com/coreos/go-oidc; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in django-allauth flask-login pyjwt passlib python-jose authlib; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
echo ""

# --- Version / Release Info ---
echo "## Versioning"
latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "no tags")
echo "- Latest git tag: $latest_tag"
tag_count=$(git tag -l 2>/dev/null | wc -l | tr -d ' ')
echo "- Total tags: $tag_count"
[ -f "CHANGELOG.md" ] && echo "- CHANGELOG.md present"
[ -f "CHANGES.md" ] && echo "- CHANGES.md present"
echo ""

echo "=== Reconnaissance Complete ==="
