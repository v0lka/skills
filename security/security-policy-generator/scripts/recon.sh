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

# --- Container Security Signals ---
# Security relevance: Step 5 container-security domain. Base image provenance and
# whether a non-root USER is set are architectural facts that determine which
# container-related threats apply (privilege escalation, image supply chain).
echo "## Container Security Signals"
if [ -f "Dockerfile" ]; then
  base_img=$(grep -iE "^FROM " Dockerfile 2>/dev/null | head -1 | sed 's/^FROM[[:space:]]*//I' || true)
  [ -n "$base_img" ] && echo "- Dockerfile base image: $base_img"
  if grep -qiE "^USER " Dockerfile 2>/dev/null; then
    echo "- Dockerfile USER directive present (non-root intent)"
  else
    echo "- Dockerfile: no USER directive (runs as root by default)"
  fi
fi
echo ""

# --- Secret & Config-Loading Patterns (architecture relevance signal) ---
# Security relevance: Step 2/Step 5. This section detects whether the codebase
# handles secrets/config at all — that marks the "secret management" domain as
# applicable to the threat model. It is NOT a leak audit: counts indicate
# surface area, not compliance findings (see SKILL.md Scope Boundary).
echo "## Secret & Config-Loading Patterns (relevance signal)"
echo "(Indicates the secret-management domain applies; not a leak audit)"
# Env / config-loading patterns present (structural signal — secrets handled in code)
env_count=$(grep -rIlE '(process\.env|os\.environ|os\.getenv|getenv\(|config\.get|Config\.Get|viper\.Get|envconfig|@Value\(|@ConfigurationProperties|Environment\.getenv)' \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.rs" --include="*.java" --include="*.rb" --include="*.cs" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || env_count=0
echo "- Files reading env/config at runtime: $env_count"
# .env files present
env_file_count=$(find . -maxdepth 3 -name '.env*' \
  -not -path '*/node_modules/*' -not -path '*/vendor/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ') || env_file_count=0
[ "${env_file_count:-0}" -gt 0 ] && echo "- .env files present: $env_file_count"
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

# --- API Surface / Contracts ---
# Security relevance: attack-surface sizing. Contract files define the public
# input boundary (routes, operations, schemas). Their presence signals that the
# input-validation / AuthZ / rate-limiting domains apply (Step 3 & Step 5).
echo "## API Surface & Contracts"
echo "(Contract files define the entry boundary; route counts size the surface)"
# Contract/spec files
for spec in openapi.json openapi.yaml openapi.yml swagger.json swagger.yaml \
            asyncapi.json asyncapi.yaml asyncapi.yml; do
  [ -f "$spec" ] && echo "- OpenAPI/AsyncAPI spec present: $spec"
done
# gRPC proto files
proto_count=$(find . -maxdepth 4 -name '*.proto' \
  -not -path '*/node_modules/*' -not -path '*/vendor/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ') || true
[ "${proto_count:-0}" -gt 0 ] && echo "- gRPC proto files: $proto_count"
# GraphQL schema files
gql_count=$(find . -maxdepth 4 \( -name '*.graphql' -o -name 'schema.graphql' -o -name '*.gql' \) \
  -not -path '*/node_modules/*' -not -path '*/vendor/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ') || true
[ "${gql_count:-0}" -gt 0 ] && echo "- GraphQL schema files: $gql_count"
# Route-definition counts across stacks (sizing, not auditing)
route_count=$(grep -rIlE '(@app\.(get|post|put|delete|patch|route)|@(Get|Post|Put|Delete|Patch|RequestMapping)Mapping|app\.(get|post|put|delete|patch)\(|router\.(Get|Post|Put|Delete|Patch)\(|@(Get|Post|Put|Delete)\(|\.Handle\(|c\.GET\(|\.GET\()' \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.java" --include="*.cs" --include="*.rb" --include="*.php" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
echo "- Files with route/handler definitions (surface sizing): ${route_count:-0}"
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

# --- DB Migrations & Schemas ---
# Security relevance: asset discovery (Step 2). Migrations/schema files are where
# PII, credentials, and financial columns are declared — the threat model needs to
# know where sensitive data models live.
echo "## DB Migrations & Schemas"
[ -d "migrations" ] && echo "- migrations/ directory present"
[ -d "db/migrations" ] && echo "- db/migrations/ directory present"
[ -f "prisma/schema.prisma" ] && echo "- Prisma schema present (prisma/schema.prisma)"
[ -d "alembic" ] && echo "- Alembic migrations present (alembic/)"
[ -d "flyway" ] || find . -maxdepth 3 -path '*/db/migration' -type d 2>/dev/null | head -1 | grep -q . && echo "- Flyway migrations present"
gorm_auto=$(grep -rIl 'AutoMigrate' --include="*.go" . 2>/dev/null | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
[ "${gorm_auto:-0}" -gt 0 ] && echo "- GORM AutoMigrate calls (Go schema): $gorm_auto files"
sql_count=$(find . -maxdepth 3 \( -name '*.sql' -o -name '*.ddl' \) \
  -not -path '*/node_modules/*' -not -path '*/vendor/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ') || true
[ "${sql_count:-0}" -gt 0 ] && echo "- SQL schema/migration files: $sql_count"
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

# --- WebSocket Servers (real-time bidirectional entry points) ---
# Security relevance: Step 3 attack surface. WebSocket connections bypass many
# HTTP-centric controls (CSRF tokens, same-origin) and need origin validation,
# message rate limiting, and AuthZ on connect.
echo "## WebSocket Servers"
if [ -f "package.json" ]; then
  for lib in ws socket.io @fastify/websocket "@socket.io/cluster-adapter" sockjs nanomsg; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in gorilla/websocket coder/websocket gobwas/ws nhooyr.io/websocket; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in websockets aiohttp wsproto autobahn; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in tokio-tungstenite tungstenite axum; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust: $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in Microsoft.AspNetCore.WebSockets System.Net.WebSockets; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
ws_count=$(grep -rIlE '(Upgrade.*websocket|WebSocket\(|on\s*\(\s*[''"]connection[''"]|@app\.websocket|c\.WebSocket|HandleWebSocket)' \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.java" --include="*.cs" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
[ "${ws_count:-0}" -gt 0 ] && echo "- Files with WebSocket handlers: $ws_count"
echo ""

# --- Async / Messaging / Webhook Receivers ---
# Security relevance: Step 3 attack surface. Message consumers and webhook
# receivers process untrusted external input asynchronously — they are entry
# points that need input validation and AuthZ just like HTTP routes.
echo "## Async / Messaging / Webhook Receivers"
if [ -f "package.json" ]; then
  for lib in bull bullmq agenda kafkajs amqplib rsmq sqs-consumer "@aws-sdk/client-sqs" "@aws-sdk/client-sns" "@aws-sdk/client-eventbridge" mqtt typed-rx-emitter; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm: $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in IBM/sarama segmentio/kafka-go rabbitmq/amqp091-go nats-io/nats-go nsqio/nsqgo redis/go-redis aws/aws-sdk-go-v2/service/sqs aws/aws-sdk-go-v2/service/sns; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go: $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in kafka-python confluent-kafka pika redis-rq hq dramatiq huey aio-pika; do
    grep -qiE "^${lib}" requirements.txt 2>/dev/null && echo "- python: $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python: $lib"
  done
  # Celery / RQ are often declared without a version pin
  grep -qiE "^(celery|rq)" requirements.txt pyproject.toml 2>/dev/null && echo "- python: celery/rq (task queue)"
fi
if [ -f "Gemfile" ]; then
  for lib in sidekiq shoryuken sneakers bunny; do
    grep -q "$lib" Gemfile 2>/dev/null && echo "- ruby: $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  for lib in MassTransit Hangfire Azure.Messaging.ServiceBus Confluent.Kafka RabbitMQ.Client; do
    grep -q "$lib" "$csproj" 2>/dev/null && echo "- csharp: $lib"
  done
done
# Webhook-receiver handlers (framework-agnostic signature)
webhook_count=$(grep -rIlE '(/webhook|webhook_handler|@app\.post.*webhook|register_webhook|handle_event|process_event)' \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.java" --include="*.rb" --include="*.php" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
[ "${webhook_count:-0}" -gt 0 ] && echo "- Files with webhook/event-handler patterns: $webhook_count"
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

# --- Security Domain Libraries (architecture-relevance signals) ---
# Security relevance: Step 5. Each library below marks a security DOMAIN as
# applicable to this architecture (not an audit of correctness). The threat
# model and coding rules must cover every domain flagged here.
echo "## Security Domain Libraries (relevance signals)"
# Rate limiting
if [ -f "package.json" ]; then
  for lib in express-rate-limit "@fastify/rate-limit" koa-ratelimit express-slow-down; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (rate-limiting): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in slowapi flask-limiter; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (rate-limiting): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (rate-limiting): $lib"
  done
fi
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  grep -q "AspNetCoreRateLimit" "$csproj" 2>/dev/null && echo "- csharp (rate-limiting): AspNetCoreRateLimit"
done
# CSRF
if [ -f "package.json" ]; then
  for lib in csurf; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (CSRF): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  grep -qiE "^(flask-wtf|django.middleware.csrf)" requirements.txt pyproject.toml 2>/dev/null && echo "- python (CSRF): flask-wtf / django csrf middleware"
fi
# Security headers
if [ -f "package.json" ]; then
  for lib in helmet secure; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (security-headers): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in flask-talisman django-csp; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (security-headers): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (security-headers): $lib"
  done
fi
# Crypto
if [ -f "package.json" ]; then
  grep -q "\"node:crypto\"" package.json 2>/dev/null && echo "- npm (crypto): node:crypto"
fi
if [ -f "go.mod" ]; then
  grep -q "crypto/aes\|crypto/cipher\|golang.org/x/crypto" go.mod 2>/dev/null && echo "- go (crypto): golang.org/x/crypto / crypto/aes"
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in cryptography pynacl; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (crypto): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (crypto): $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in aes ring rustls libsodium-sys; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust (crypto): $lib"
  done
fi
# Secret management SDKs
if [ -f "package.json" ]; then
  for lib in "@aws-sdk/client-secrets-manager" "@aws-sdk/client-ssm"; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (secret-mgmt): $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in hashicorp/vault aws/aws-sdk-go-v2/service/secretsmanager; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go (secret-mgmt): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in hvac boto3; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (secret-mgmt): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (secret-mgmt): $lib"
  done
fi
echo ""

# --- Agentic AI Indicators (OWASP Top 10 for Agentic Applications 2026) ---
# Security relevance: these signal that the project builds AI agents that plan,
# act, call tools, remember, or communicate with other agents. When ANY of these
# are present, the agentic threat model applies — in addition to classical
# controls. Maps to ASI01-ASI10 (see SKILL.md and template.md).
echo "## Agentic AI Indicators (OWASP Top 10 for Agentic Applications 2026)"
echo "(Presence triggers the agentic threat-model section: ASI01-ASI10)"
# --- LLM / Inference SDKs ---
if [ -f "package.json" ]; then
  for lib in openai @anthropic-ai/sdk @google/generative-ai @google/genai groq-sdk ai @ai-sdk/openai @ai-sdk/anthropic ollama mistralai; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (LLM SDK): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in openai anthropic google-generativeai google-genai groq ollama mistralai vertexai; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (LLM SDK): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (LLM SDK): $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in sashabaranov/go-openai google/generative-ai-go; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go (LLM SDK): $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in async-openai genai; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust (LLM SDK): $lib"
  done
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  src_file="pom.xml"
  [ -f "build.gradle" ] && src_file="build.gradle"
  [ -f "build.gradle.kts" ] && src_file="build.gradle.kts"
  for lib in spring-ai dev.langchain4j; do
    grep -q "$lib" "$src_file" 2>/dev/null && echo "- java (LLM SDK): $lib"
  done
fi
# --- Agent frameworks / orchestration (ASI01/ASI02/ASI10) ---
if [ -f "package.json" ]; then
  for lib in langchain @langchain/core @langchain/community langgraph @langchain/langgraph @langchain/langgraph-sdk; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (agent framework): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in langchain langchain-core langchain-community langgraph crewai autogen pyautogen autogen-agentchat semantic-kernel haystack dspy llama-index llama_index phidata agno; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (agent framework): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (agent framework): $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in tmc/langchaingo; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go (agent framework): $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in langchain-rust rig-core; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust (agent framework): $lib"
  done
fi
# --- MCP (Model Context Protocol) — tool registries, ASI04 supply chain ---
if [ -f "package.json" ]; then
  for lib in @modelcontextprotocol/sdk; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (MCP): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in mcp; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (MCP): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (MCP): $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in mark3labs/mcp-go modelcontextprotocol/go-sdk; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go (MCP): $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in rmcp; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust (MCP): $lib"
  done
fi
# --- MCP / tool config files ---
for mcpfile in .mcp.json mcp.json mcp-config.json .cursor/mcp.json; do
  [ -f "$mcpfile" ] && echo "- MCP config file present: $mcpfile"
done
# --- Vector stores / persistent memory (ASI06) ---
if [ -f "package.json" ]; then
  for lib in chromadb @chroma-core/default-embed @pinecone-database/pinecone weaviate-ts-client @qdrant/js-client-rest vectordb; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (vector store): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in chromadb pinecone pinecone-client weaviate-client qdrant-client pymilvus faiss-cpu pgvector; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (vector store): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (vector store): $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in pgvector/pgvector-go weaviate/weaviate-go-client qdrant/go-client; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go (vector store): $lib"
  done
fi
if [ -f "Cargo.toml" ]; then
  for lib in qdrant-client; do
    grep -q "\"$lib\"" Cargo.toml 2>/dev/null && echo "- rust (vector store): $lib"
  done
fi
# --- LLM gateways / proxies (ASI03/ASI04 — agent identity & supply chain) ---
if [ -f "package.json" ]; then
  for lib in litellm portkey-ai "@llamaindex/portkey" helicone; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (LLM gateway/proxy): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in litellm portkey-ai; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (LLM gateway/proxy): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (LLM gateway/proxy): $lib"
  done
fi
# --- Guardrails / policy engines (ASI01/ASI02/ASI09 — input/output filtering, approval) ---
if [ -f "package.json" ]; then
  for lib in guardrails "@guardrails-ai/core" lattice-llm; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (guardrails/policy): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in guardrails-ai nemoguardrails guardrails; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (guardrails/policy): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (guardrails/policy): $lib"
  done
fi
# --- Code-execution sandboxes (ASI05 — agent-generated code / shell) ---
if [ -f "package.json" ]; then
  for lib in "@e2b/code-interpreter" e2b modalsandbox; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (code-exec sandbox): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in e2b codeinterpreter_api; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (code-exec sandbox): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (code-exec sandbox): $lib"
  done
fi
if [ -f "go.mod" ]; then
  for lib in e2b-dev/E2B; do
    grep -q "$lib" go.mod 2>/dev/null && echo "- go (code-exec sandbox): $lib"
  done
fi
# Sandbox-as-container pattern: docker used as exec backend for agent code
docker_exec=$(grep -rIlE '(runCode|exec_sandbox|execute_code|code_interpreter|sandbox_exec|run_python|runSandbox)' \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.java" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
[ "${docker_exec:-0}" -gt 0 ] && echo "- Files with code-execution/sandbox patterns (ASI05): $docker_exec"
# --- LLM observability / tracing (ASI08/ASI10 — auditable receipt chain, cascade monitoring) ---
if [ -f "package.json" ]; then
  for lib in langfuse helicone "@arize/phoenix-openinference"; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (LLM observability): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in langfuse helicone arize opentelemetry-instrumentation-openai; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (LLM observability): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (LLM observability): $lib"
  done
fi
# --- Eval / alignment frameworks (ASI10 — periodic alignment checks) ---
if [ -f "package.json" ]; then
  for lib in promptfoo; do
    grep -q "\"$lib\"" package.json 2>/dev/null && echo "- npm (eval/alignment): $lib"
  done
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  for lib in deepeval ragas promptfoo; do
    grep -qiE "^$lib" requirements.txt 2>/dev/null && echo "- python (eval/alignment): $lib"
    grep -qi "$lib" pyproject.toml 2>/dev/null && echo "- python (eval/alignment): $lib"
  done
fi
# --- Prompt / agent instruction files (ASI01 vectors & ASI06 memory) ---
for pfile in AGENTS.md CLAUDE.md .cursorrules .windsurfrules .github/copilot-instructions.md; do
  [ -f "$pfile" ] && echo "- Agent/prompt instruction file: $pfile"
done
find . -maxdepth 3 \( -name '*.prompt' -o -name '*.prompt.txt' -o -name 'system_prompt*' -o -name 'system-prompt*' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | head -10 | while read -r f; do
  echo "- Prompt file: $f"
done
[ -d "prompts" ] && echo "- prompts/ directory present"
# --- Agentic summary flag ---
if grep -rEq "\"(openai|@anthropic-ai/sdk|@google/generative-ai|@google/genai|langchain|@langchain/core|langgraph|@modelcontextprotocol/sdk|chromadb|ai|litellm|portkey-ai|guardrails-ai|nemoguardrails|guardrails|e2b|langfuse|helicone|crewai|phidata|agno|@e2b/code-interpreter)\"" package.json 2>/dev/null \
  || grep -qiE "^(openai|anthropic|langchain|langgraph|crewai|autogen|pyautogen|chromadb|mcp|google-generativeai|google-genai|llama-index|llama_index|litellm|portkey-ai|guardrails-ai|nemoguardrails|guardrails|e2b|langfuse|helicone|deepeval|ragas|promptfoo|phidata|agno)\b" requirements.txt pyproject.toml 2>/dev/null \
  || grep -qE "sashabaranov/go-openai|tmc/langchaingo|mark3labs/mcp-go|e2b-dev/E2B" go.mod 2>/dev/null; then
  echo "- AGENTIC PROJECT DETECTED: generate the OWASP Top 10 for Agentic Applications (ASI01-ASI10) section"
else
  echo "- No strong agentic indicators: agentic section may be omitted (classical controls suffice)"
fi
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

# --- Security-Relevant Code Patterns (domain-relevance signals) ---
# Security relevance: Step 5. Counts below indicate which classical threat
# domains apply to this architecture (injection, deserialization, dynamic
# execution, XXE). They are relevance signals for the threat model and coding
# rules — NOT compliance findings (see SKILL.md Scope Boundary).
echo "## Security-Relevant Code Patterns (relevance signals)"
echo "(Indicates which threat domains apply; not a compliance audit)"
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

# --- Agentic Pattern Signals (ASI relevance indicators) ---
# Security relevance: Step 6. Counts below show which ASI categories are
# architecturally relevant (tool-calling → ASI02, delegation → ASI07, HITL →
# ASI09). Relevance signals for the agentic threat model — not a compliance
# verdict (see SKILL.md Scope Boundary).
echo "## Agentic Pattern Signals (ASI relevance indicators)"
# Tool / function-calling definitions (ASI02 tool misuse surface)
toolcall_count=$(grep -rIlE '("type"[[:space:]]*:[[:space:]]*"function"|function_call|tool_calls|tools[[:space:]]*:[[:space:]]*\[|@tool|FunctionTool|registerTool|register_tool)' \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.java" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
echo "- Files with tool/function-calling definitions (ASI02): $toolcall_count"
# Inter-agent delegation / orchestration patterns (ASI07 / ASI10)
delegate_count=$(grep -rIlE '(delegate_to|delegateto|forward_to|orchestrator|subagent|sub_agent|multi.?agent|handoff)' \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.java" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
echo "- Files with inter-agent delegation/orchestration (ASI07/ASI10): $delegate_count"
# Human-in-the-loop / approval gates (ASI09 — presence indicates a control)
hitl_count=$(grep -rIlE '(require_approval|require-human-approval|human_in_the_loop|human-in-the-loop|approval_required|askUser|ask_user)' \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.go" . 2>/dev/null \
  | grep -v node_modules | grep -v vendor | grep -v '.git/' | wc -l | tr -d ' ') || true
echo "- Files with human-approval gates (ASI09 relevance indicator): $hitl_count"
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
