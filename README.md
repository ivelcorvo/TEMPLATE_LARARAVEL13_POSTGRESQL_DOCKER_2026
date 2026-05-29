# Laravel Template

Este template foi desenvolvido com auxílio de IA — especificamente o Claude (Anthropic).

Template Docker profissional para projetos Laravel 13 — pronto para APIs, com opção de adicionar Livewire 4 depois.

Stack: **PHP 8.4** · **Laravel 13** · **PostgreSQL 16** · **Redis 7** · **Nginx 1.27** · **Mailpit**

---

## O que vem pronto

- `Dockerfile` PHP-FPM com OPcache + JIT, extensões `pdo_pgsql`, `redis`, `intl`, `gd`, `bcmath`, `zip`, `exif`, `pcntl`.
- `docker-compose.yml` moderno com healthchecks no Postgres/Redis e `depends_on: service_healthy`.
- Nginx pré-configurado: roteamento Laravel, FastCGI, cache de assets, headers de segurança, bloqueio de arquivos sensíveis.
- `php.ini` pronto para API pura ou API + Livewire — comentado linha a linha.
- Queue worker e Scheduler como **profiles** — sobem só quando você pedir.
- Mailpit incluso (UI em `http://localhost:8025`).
- `.env.example` documentado.
- Usuário não-root no container, UID/GID alinhados com o host.

**Não vem:** código de aplicação, autenticação, Livewire instalado. É só a fundação.

---

## Pré-requisitos

- Docker Engine 24+ e Docker Compose v2+
- Git

---

## Uso

Existem dois caminhos. Escolha conforme o cenário.

### Cenário A — Começar um projeto Laravel do zero

**1. Clonar e entrar na pasta**
```bash
git clone <url-deste-template> meu-projeto && cd meu-projeto
```

**2. Copiar o .env**
```bash
cp .env.example .env
```
> Edite `APP_SLUG`, `DB_PASSWORD`, `REDIS_PASSWORD`

**3. Buildar e subir**
```bash
docker compose build && docker compose up -d
```

**4. Criar o Laravel 13 dentro de src/**
```bash
docker compose run --rm app composer create-project laravel/laravel:^13.0 . --no-scripts
```
O --no-scripts impede que ele rode os scripts pós-instalação (key:generate, migrations). assim podemos sobrescreve o src/.env, gera a key manualmente e roda as migrations na hora certa.

> Se travar por timeout, aumente o limite:
```bash
docker compose exec -e COMPOSER_PROCESS_TIMEOUT=2000 app composer create-project laravel/laravel:^13.0 . --no-scripts
```

**5. Configurar a aplicação**
```bash
cp .env src/.env && docker compose exec app php artisan key:generate && docker compose exec app php artisan migrate
```

**6. Acessar**

| Serviço  | Endereço               |
|----------|------------------------|
| API/Web  | http://localhost:8080  |
| Mailpit  | http://localhost:8025  |
| Postgres | localhost:5432         |
| Redis    | localhost:6379         |

---

### Cenário B — Já tenho um projeto Laravel existente

**1. Clonar e entrar na pasta**
```bash
git clone <url-deste-template> meu-projeto && cd meu-projeto
```

**2. Copiar seu projeto para dentro de src/**
```bash
rsync -a --exclude=vendor --exclude=node_modules /caminho/do/seu/projeto/ src/
```

**3. Copiar o .env**
```bash
cp .env.example .env
```
> Ajuste `APP_SLUG`, `DB_*`, `REDIS_*`
>
> Dentro do container os hosts são os nomes dos serviços: `DB_HOST=postgres`, `REDIS_HOST=redis`, `MAIL_HOST=mailpit`

**4. Buildar e subir**
```bash
docker compose build && docker compose up -d
```

**5. Instalar dependências e rodar migrations**
```bash
docker compose exec app composer install && docker compose exec app php artisan migrate
```

---

## Comandos do dia a dia

**Subir os serviços**
```bash
docker compose up -d
```

**Parar tudo (mantém volumes)**
```bash
docker compose down
```

**Parar tudo e APAGAR o banco**
```bash
docker compose down -v
```

**Ver logs**
```bash
docker compose logs -f --tail=100
```

**Abrir shell no container**
```bash
docker compose exec -it app bash
```

**Rodar migrations**
```bash
docker compose exec app php artisan migrate
```

**Drop e recriar banco + seed**
```bash
docker compose exec app php artisan migrate:fresh --seed
```

**Tinker**
```bash
docker compose exec app php artisan tinker
```

**Listar rotas**
```bash
docker compose exec app php artisan route:list
```

**Rodar testes**
```bash
docker compose exec app php artisan test
```

**Limpar caches**
```bash
docker compose exec app php artisan optimize:clear
```

---

## Instalando recursos comuns

### Sanctum (autenticação de API por token)

```bash
docker compose exec app composer require laravel/sanctum
```
```bash
docker compose exec app php artisan install:api && docker compose exec app php artisan migrate
```

### Spatie Permission (roles e permissões)

```bash
docker compose exec app composer require spatie/laravel-permission
```
```bash
docker compose exec app php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
```
```bash
docker compose exec app php artisan migrate
```

### Livewire 4

```bash
docker compose exec app composer require livewire/livewire
```

### Laravel Telescope (debug em dev)

```bash
docker compose exec app composer require laravel/telescope --dev
```
```bash
docker compose exec app php artisan telescope:install && docker compose exec app php artisan migrate
```

---

## Profiles do Compose

Queue worker e Scheduler não sobem por padrão — só quando você precisar:

**Só os essenciais**
```bash
docker compose up -d
```

**Com queue worker**
```bash
docker compose --profile queue up -d
```

**Com queue + scheduler**
```bash
docker compose --profile queue --profile scheduler up -d
```

---

## Estrutura do template

```
.
├── Dockerfile
├── docker-compose.yml
├── docker/
│   ├── nginx/default.conf
│   └── php/php.ini
├── .env.example
├── .dockerignore
├── .gitignore
├── README.md
└── src/                  ← seu Laravel mora aqui
```

---

## Produção — checklist

- [ ] `APP_ENV=production` e `APP_DEBUG=false`
- [ ] `APP_URL` com HTTPS
- [ ] `SESSION_SECURE_COOKIE=true`
- [ ] Senhas fortes em `DB_PASSWORD` e `REDIS_PASSWORD`
- [ ] Comentar `ports:` de `postgres` e `redis` no `docker-compose.yml`
- [ ] `opcache.validate_timestamps=0` no `php.ini`
- [ ] `php artisan config:cache && route:cache && view:cache`
- [ ] Adicionar HSTS no Nginx: `add_header Strict-Transport-Security "max-age=31536000" always;`
- [ ] Backups automáticos do volume `postgres_data`

---

## Licença

MIT. Use, modifique e distribua livremente.
