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
[ -f "build.sbt" ] && detected_stack+=("Scala")
# C/C++ — detected via source files, not a package manager
find . -maxdepth 3 -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' 2>/dev/null | head -1 > /dev/null && detected_stack+=("C/C++")
find . -maxdepth 3 -name '*.swift' 2>/dev/null | head -1 > /dev/null && detected_stack+=("Swift")

if [ ${#detected_stack[@]} -eq 0 ]; then
  echo "- Could not auto-detect stack"
else
  for s in "${detected_stack[@]}"; do echo "- $s"; done
fi
echo ""

# --- Build Tools ---
echo "## Build Tools"
[ -f "Makefile" ] && echo "- Make"
[ -f "build.sbt" ] && echo "- SBT (Scala)"
[ -f "pnpm-lock.yaml" ] && echo "- PNPM"
[ -f "poetry.lock" ] || [ -f "pyproject.toml" ] && grep -q "tool.poetry" pyproject.toml 2>/dev/null && echo "- Poetry"
[ -f "Pipfile" ] && echo "- Pipenv"
[ -f "Gemfile.lock" ] && echo "- Bundler (Ruby)"
[ -f "yarn.lock" ] && echo "- Yarn"
[ -f "Rakefile" ] && echo "- Rake (Ruby)"
# csproj signals NuGet indirectly
ls *.csproj 2>/dev/null | head -1 > /dev/null && echo "- NuGet (via csproj)"

# Fallback for common tools already detected in stack section
[ -f "package.json" ] && echo "- npm"
[ -f "go.mod" ] && echo "- Go Modules"
[ -f "Cargo.toml" ] && echo "- Cargo (Rust)"
[ -f "pom.xml" ] && echo "- Maven (Java)"
[ -f "build.gradle" ] || [ -f "build.gradle.kts" ] && echo "- Gradle (Java/Kotlin)"
[ -f "requirements.txt" ] && echo "- pip"
echo ""

# --- Deployment Detection ---
echo "## Deployment Indicators"
[ -f "Dockerfile" ] && echo "- Dockerfile found"
[ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] && echo "- Docker Compose found"
[ -d "k8s" ] || [ -d "kubernetes" ] || [ -d "deploy/k8s" ] && echo "- Kubernetes manifests found"
[ -f "serverless.yml" ] || [ -f "serverless.yaml" ] && echo "- Serverless framework found"
[ -d "terraform" ] || [ -f "main.tf" ] && echo "- Terraform found"
[ -f ".github/workflows/"* ] 2>/dev/null && echo "- GitHub Actions found"
[ -f ".circleci/config.yml" ] 2>/dev/null || [ -d ".circleci" ] && echo "- CircleCI found"
[ -f ".gitlab-ci.yml" ] && echo "- GitLab CI found"
[ -f "Jenkinsfile" ] && echo "- Jenkins found"
[ -d "chart" ] || [ -f "helmfile.yaml" ] || ls Chart.yaml 2>/dev/null | head -1 > /dev/null && echo "- Helm found"
[ -f "nginx.conf" ] || [ -d "nginx" ] && echo "- Nginx config found"
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
count=$(grep -rIlE "$patterns" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.rs" --include="*.java" --include="*.rb" --include="*.env.example" --include="*.yaml" --include="*.yml" . 2>/dev/null | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || count=0
echo "- Files with potential secret patterns: $count"
echo ""

# --- Web Frameworks ---
# Security relevance: RCE, injection (SQL/NoSQL/CMD), path traversal, SSRF, auth bypass.
echo "## Web Frameworks Detected"
# Node.js
if [ -f "package.json" ]; then
  for lib in express fastify koa hapi nestjs @nestjs/core sails adonis @adonisjs/core @feathersjs; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
# Go
if [ -f "go.mod" ]; then
  for lib in gin-gonic/gin labstack/echo gofiber/fiber gorilla/mux go-chi/chi beego/beego kataras/iris revel/revel valyala/fasthttp; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
# Python
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in django flask fastapi starlette pyramid tornado bottle sanic aiohttp quart cherrypy falcon; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
# Rust
if [ -f "Cargo.toml" ]; then
  for lib in actix-web axum rocket warp tide poem ntex salvo; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust: $lib"
  done
fi
# Java/Kotlin
if [ -f "pom.xml" ]; then
  for lib in spring-boot-starter-web spring-boot-starter-webflux javalin spark-core vertx-web ktor-server-core; do
    grep -q "$lib" pom.xml 2>/dev/null && echo "- java: $lib"
  done
fi
if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  for lib in spring-boot-starter-web spring-boot-starter-webflux javalin spark-core vertx-web ktor-server-core; do
    gradle_file="build.gradle"
    [ -f "build.gradle.kts" ] && gradle_file="build.gradle.kts"
    grep -q "$lib" "$gradle_file" 2>/dev/null && echo "- java: $lib"
  done
fi
# PHP
if [ -f "composer.json" ]; then
  for lib in laravel/framework symfony/http-foundation slim/slim cakephp/cakephp laminas/laminas-mvc codeigniter4/framework; do
    grep -q "\"$lib\"" composer.json 2>/dev/null && echo "- php: $lib"
  done
fi
# Scala
if [ -f "build.sbt" ]; then
  for lib in play-framework akka-http http4s; do
    grep -q "$lib" build.sbt 2>/dev/null && echo "- scala: $lib"
  done
fi
# Ruby
if [ -f "Gemfile" ]; then
  for lib in rails sinatra grape hanami roda; do
    grep -q "$lib" Gemfile 2>/dev/null && echo "- ruby: $lib"
  done
fi
# C#/.NET
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in Microsoft.AspNetCore.App Microsoft.AspNetCore.Mvc Microsoft.AspNetCore.Blazor; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
echo ""

# --- ORM / Database Libraries ---
# Security relevance: SQL injection, NoSQL injection, credential exposure.
echo "## ORM / Database Libraries"
if [ -f "package.json" ]; then
  for lib in sequelize prisma @prisma/client typeorm knex objection mongoose mikro-orm @mikro-orm/core drizzle-orm pg mysql2 better-sqlite3 ioredis; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in gorm.io/gorm jmoiron/sqlx jackc/pgx entgo.io/ent uptrace/bun go-sql-driver/mysql lib/pq mattn/go-sqlite3 ClickHouse/clickhouse-go; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in sqlalchemy django-orm peewee tortoise-orm asyncpg psycopg2 psycopg pymongo motor redis aioredis; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in diesel sea-orm tokio-postgres mongodb; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust: $lib"
  done
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  src_file="pom.xml"
  [ -f "build.gradle" ] && src_file="build.gradle"
  [ -f "build.gradle.kts" ] && src_file="build.gradle.kts"
  for lib in hibernate-core mybatis mybatis-spring-boot-starter jooq exposed-core; do
    grep -q "$lib" "$src_file" 2>/dev/null && echo "- java: $lib"
  done
fi
if [ -f "composer.json" ]; then
  for lib in illuminate/database doctrine/orm doctrine/dbal propel/propel cycle/orm; do
    grep -q "\"$lib\"" composer.json 2>/dev/null && echo "- php: $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in Microsoft.EntityFrameworkCore Dapper NHibernate linq2db; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
echo ""

# --- Authentication Libraries ---
echo "## Authentication Libraries Detected"
if [ -f "package.json" ]; then
  for lib in passport jsonwebtoken jose next-auth @auth bcrypt argon2 express-session openid-client lucia-auth @auth/core cookie-parser; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in golang.org/x/crypto github.com/golang-jwt github.com/coreos/go-oidc casbin/casbin golang.org/x/oauth2 markbates/goth go-jose/go-jose; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in django-allauth flask-login flask-jwt-extended pyjwt passlib python-jose authlib bcrypt django-oauth-toolkit fastapi-users; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in oauth2 openidconnect jsonwebtoken argon2 bcrypt password-hash; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust: $lib"
  done
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  src_file="pom.xml"
  [ -f "build.gradle" ] && src_file="build.gradle"
  [ -f "build.gradle.kts" ] && src_file="build.gradle.kts"
  for lib in spring-boot-starter-security spring-security-oauth2 shiro-core pac4j-core keycloak-core nimbus-jose-jwt jjwt; do
    grep -q "$lib" "$src_file" 2>/dev/null && echo "- java: $lib"
  done
fi
if [ -f "composer.json" ]; then
  for lib in laravel/sanctum laravel/passport tymon/jwt-auth league/oauth2-server; do
    grep -q "\"$lib\"" composer.json 2>/dev/null && echo "- php: $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in Microsoft.AspNetCore.Identity JwtBearer OpenIdConnect IdentityServer4 OpenIddict; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
if [ -f "Gemfile" ]; then
  for lib in devise omniauth pundit cancan cancancan sorcery warden rodauth; do
    grep -q "$lib" Gemfile 2>/dev/null && echo "- ruby: $lib"
  done
fi
echo ""

# --- Template Engines (SSTI risk) ---
echo "## Template Engines (potential SSTI risk)"
if [ -f "package.json" ]; then
  for lib in ejs pug handlebars mustache nunjucks liquidjs; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in flosch/pongo2 CloudyKit/jet; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in jinja2 mako chameleon; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in tera askama handlebars minijinja liquid; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust: $lib"
  done
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  src_file="pom.xml"
  [ -f "build.gradle" ] && src_file="build.gradle"
  [ -f "build.gradle.kts" ] && src_file="build.gradle.kts"
  for lib in thymeleaf freemarker velocity pebble; do
    grep -q "$lib" "$src_file" 2>/dev/null && echo "- java: $lib"
  done
fi
if [ -f "composer.json" ]; then
  for lib in twig/twig smarty/smarty league/plates; do
    grep -q "\"$lib\"" composer.json 2>/dev/null && echo "- php: $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in Scriban Handlebars.Net DotLiquid; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
echo ""

# --- Serialization Libraries (insecure deserialization risk) ---
echo "## Serialization Libraries (deserialization risk)"
if [ -f "package.json" ]; then
  for lib in zod yup joi ajv class-validator class-transformer; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in gopkg.in/yaml BurntSushi/toml vmihailenco/msgpack; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in pydantic marshmallow cattrs pyyaml lxml dill; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in serde serde_json serde_yaml serde_xml bincode; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust: $lib"
  done
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  src_file="pom.xml"
  [ -f "build.gradle" ] && src_file="build.gradle"
  [ -f "build.gradle.kts" ] && src_file="build.gradle.kts"
  for lib in jackson-databind gson snakeyaml xstream kotlinx-serialization; do
    grep -q "$lib" "$src_file" 2>/dev/null && echo "- java: $lib"
  done
fi
if [ -f "composer.json" ]; then
  for lib in symfony/serializer jms/serializer; do
    grep -q "\"$lib\"" composer.json 2>/dev/null && echo "- php: $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in Newtonsoft.Json System.Text.Json protobuf-net MessagePack; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
echo ""

# --- HTTP Clients (SSRF risk) ---
echo "## HTTP Clients (SSRF risk)"
if [ -f "package.json" ]; then
  for lib in axios node-fetch got undici superagent; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in go-resty/resty hashicorp/go-retryablehttp; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in requests httpx urllib3 treq; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in reqwest hyper ureq awc; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust: $lib"
  done
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  src_file="pom.xml"
  [ -f "build.gradle" ] && src_file="build.gradle"
  [ -f "build.gradle.kts" ] && src_file="build.gradle.kts"
  for lib in okhttp retrofit feign-core; do
    grep -q "$lib" "$src_file" 2>/dev/null && echo "- java: $lib"
  done
fi
if [ -f "composer.json" ]; then
  for lib in guzzlehttp/guzzle symfony/http-client; do
    grep -q "\"$lib\"" composer.json 2>/dev/null && echo "- php: $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in RestSharp Flurl.Http Refit; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
echo ""

# --- GraphQL Libraries ---
echo "## GraphQL Libraries"
if [ -f "package.json" ]; then
  for lib in apollo-server @apollo/server graphql-yoga type-graphql nexus mercurius; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in graphql-go/graphql 99designs/gqlgen; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in graphene strawberry ariadne; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in async-graphql juniper; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust: $lib"
  done
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  src_file="pom.xml"
  [ -f "build.gradle" ] && src_file="build.gradle"
  [ -f "build.gradle.kts" ] && src_file="build.gradle.kts"
  for lib in graphql-java netflix-graphql-dgs graphql-java-kickstart; do
    grep -q "$lib" "$src_file" 2>/dev/null && echo "- java: $lib"
  done
fi
if [ -f "composer.json" ]; then
  for lib in nuwave/lighthouse webonyx/graphql-php rebing/graphql-laravel; do
    grep -q "\"$lib\"" composer.json 2>/dev/null && echo "- php: $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in HotChocolate GraphQL.Server; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
if [ -f "build.sbt" ]; then
  for lib in sangria; do
    grep -q "$lib" build.sbt 2>/dev/null && echo "- scala: $lib"
  done
fi
echo ""

# --- Cloud SDKs ---
echo "## Cloud SDKs"
if [ -f "go.mod" ]; then
  for lib in aws/aws-sdk-go-v2 aws/aws-sdk-go cloud.google.com/go Azure/azure-sdk-for-go; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in boto3 botocore google-cloud-storage google-cloud-bigquery azure-storage-blob azure-identity; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  src_file="pom.xml"
  [ -f "build.gradle" ] && src_file="build.gradle"
  [ -f "build.gradle.kts" ] && src_file="build.gradle.kts"
  for lib in aws-java-sdk aws-java-sdk-s3; do
    grep -q "$lib" "$src_file" 2>/dev/null && echo "- java: $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in AWSSDK Azure.Storage.Blobs Google.Cloud.Storage; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
echo ""

# --- CMS / Heavy Frameworks (large attack surface) ---
echo "## CMS / Monoliths (large attack surface)"
if [ -f "composer.json" ]; then
  for cms in drupal/core joomla/joomla-platform magento/magento2; do
    grep -q "\"$cms\"" composer.json 2>/dev/null && echo "- php: $cms"
  done
fi
# WordPress detected via content patterns
grep -rq "wp-content" --include="*.php" . 2>/dev/null && echo "- php: wordpress (pattern match)"
echo ""

# --- Tests ---
echo "## Test Frameworks & Quality"
declare -a test_frameworks=()
# Find test files — check for common patterns
find . -not -path '*/node_modules/*' -not -path '*/vendor/*' -not -path '*/.git/*' \
  -not -path '*/target/*' -not -path '*/dist/*' -not -path '*/build/*' \
  \( -name '*_test.go' -o -name '*.test.js' -o -name '*.test.ts' -o -name '*.test.tsx' \
     -o -name '*.spec.js' -o -name '*.spec.ts' -o -name '*.spec.tsx' \
     -o -name '*_test.py' -o -name 'test_*.py' -o -name '*Test.java' \
     -o -name '*_spec.rb' -o -name '*_test.rb' -o -name '*.feature' \) 2>/dev/null \
  | head -10
# Test framework detection
if [ -f "package.json" ]; then
  grep -q "\"jest\"" package.json 2>/dev/null && test_frameworks+=("Jest")
  grep -q "\"mocha\"" package.json 2>/dev/null && test_frameworks+=("Mocha")
  grep -q "\"vitest\"" package.json 2>/dev/null && test_frameworks+=("Vitest")
  grep -q "\"@playwright/test\"" package.json 2>/dev/null && test_frameworks+=("Playwright")
  grep -q "\"cypress\"" package.json 2>/dev/null && test_frameworks+=("Cypress")
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  grep -qiE "^pytest" requirements.txt 2>/dev/null && test_frameworks+=("pytest")
  grep -qi "pytest" pyproject.toml 2>/dev/null && test_frameworks+=("pytest")
  grep -qiE "^unittest" requirements.txt 2>/dev/null && test_frameworks+=("unittest")
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  src_file="pom.xml"
  [ -f "build.gradle" ] && src_file="build.gradle"
  [ -f "build.gradle.kts" ] && src_file="build.gradle.kts"
  grep -q "junit" "$src_file" 2>/dev/null && test_frameworks+=("JUnit")
  grep -q "testng" "$src_file" 2>/dev/null && test_frameworks+=("TestNG")
fi
if [ -f "Gemfile" ]; then
  grep -q "rspec" Gemfile 2>/dev/null && test_frameworks+=("RSpec")
  grep -q "minitest" Gemfile 2>/dev/null && test_frameworks+=("Minitest")
fi
if [ ${#test_frameworks[@]} -gt 0 ]; then
  for f in "${test_frameworks[@]}"; do echo "- $f"; done
fi
echo ""

# --- Go Module Metadata ---
if [ -f "go.mod" ]; then
  echo "## Go Module Metadata"
  module=$(grep "^module " go.mod 2>/dev/null | awk '{print $2}' || echo "unknown")
  echo "- Module: $module"
  go_ver=$(grep "^go " go.mod 2>/dev/null | awk '{print $2}' || echo "unknown")
  echo "- Go version: $go_ver"
  echo ""
fi

# --- Dangerous Code Patterns ---
echo "## Dangerous Code Patterns"
echo "(Searching for risky patterns — potential security concerns)"
# Subprocess / command execution
subprocess_count=$(grep -rIlE '(exec\.Command|subprocess\.(run|Popen|call)|child_process\.(exec|spawn)|Process\.Start|Runtime\.getRuntime|system\s*\(|shell_exec\s*\(|passthru\s*\()' \
  --include="*.go" --include="*.py" --include="*.js" --include="*.ts" --include="*.java" --include="*.php" --include="*.rb" --include="*.cs" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
echo "- Files with command/process execution: $subprocess_count"
# Deserialization
deser_count=$(grep -rIlE '(pickle\.(load|loads)|json\.loads|yaml\.load|ObjectInputStream|BinaryFormatter|unserialize\s*\()' \
  --include="*.go" --include="*.py" --include="*.js" --include="*.ts" --include="*.java" --include="*.php" --include="*.cs" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
echo "- Files with deserialization calls: $deser_count"
# Eval / dynamic code execution
eval_count=$(grep -rIlE '(eval\s*\(|exec\s*\(|Function\s*\(|vm\.runIn|vm\.createScript)' \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.php" --include="*.rb" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
echo "- Files with eval/dynamic execution: $eval_count"
# unsafe blocks (Rust)
if [ -f "Cargo.toml" ]; then
  unsafe_count=$(grep -rIl 'unsafe {' --include="*.rs" . 2>/dev/null | grep -v target | wc -l | tr -d ' ') || true
  echo "- Rust files with unsafe blocks: $unsafe_count"
fi
# XXE-prone XML parsing
xxe_count=$(grep -rIlE '(xml\.etree|DocumentBuilder|SAXParser|XmlDocument\.Load|simplexml_load)' \
  --include="*.py" --include="*.java" --include="*.cs" --include="*.php" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
echo "- Files with XXE-prone XML parsing: $xxe_count"
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
