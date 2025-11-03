# Docker Environment Extractor (dee)

[![Shellcheck](https://github.com/SangHakLee/docker-env-extractor/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/SangHakLee/docker-env-extractor/actions/workflows/shellcheck.yml)
[![Test Installation](https://github.com/SangHakLee/docker-env-extractor/actions/workflows/test-install.yml/badge.svg)](https://github.com/SangHakLee/docker-env-extractor/actions/workflows/test-install.yml)


> Docker 컨테이너의 환경변수를 .env 파일로 추출하는 도구

## 설치

```bash
curl -LsSf https://raw.githubusercontent.com/SangHakLee/docker-env-extractor/main/install.sh | sh
```

## 빠른 시작

```bash
# 실행 중인 모든 컨테이너 추출
dee --all

# 특정 컨테이너만 추출
dee mysql redis nginx

# 타임스탬프가 포함된 백업 생성
dee --backup --all
```

## 사용법

```bash
dee [옵션] [컨테이너...]
```

### 옵션

| 옵션 | 설명 |
|------|------|
| `-a, --all` | 실행 중인 모든 컨테이너 추출 |
| `-b, --backup` | 타임스탬프가 포함된 백업 파일 생성 |
| `-o, --output DIR` | 출력 디렉토리 (기본값: /tmp/docker-env-extractor) |
| `-v, --verbose` | 상세 출력 모드 활성화 |
| `-h, --help` | 도움말 표시 |

## 사용 예제

### 모든 컨테이너 추출

```bash
dee --all
```

출력: `/tmp/docker-env-extractor/.env_<컨테이너명>`

### 백업 모드로 추출

```bash
dee --backup mysql redis
```

출력: `/tmp/docker-env-extractor/.env_mysql_20250103_143025`

### 사용자 정의 출력 디렉토리

```bash
dee -o ./my-backups --all
```

## 출력 형식

```bash
# ========================================
# Docker Container Environment Variables
# Container: mysql
# Extracted: 2025-01-03 14:30:25
# Total: 15 variables
# ========================================

MYSQL_DATABASE=myapp
MYSQL_ROOT_PASSWORD=secret
MYSQL_USER=appuser
...
```

## 요구사항

- Linux 또는 macOS
- Docker 설치 및 실행 중
- Bash 4.0 이상

## 제거

```bash
curl -LsSf https://raw.githubusercontent.com/SangHakLee/docker-env-extractor/main/install.sh | sh -s -- --uninstall
```

## 라이선스

MIT

## 개발자

Sanghak Lee ([@sanghaklee](https://github.com/sanghaklee))
