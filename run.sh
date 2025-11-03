#!/bin/bash

# ========================================
# 🐳 Docker Container Environment Extractor
# Docker 컨테이너 환경변수를 .env 파일로 추출
# ========================================

set -e

# 색상 코드 정의
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
NC=$'\033[0m'

# 설정
OUTPUT_DIR="/tmp/docker-env-extractor"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PREFIX=".env"
CREATE_BACKUP=false
VERBOSE=false

# 컨테이너 이름 배열 (여기에 추출할 컨테이너 이름 추가)
CONTAINERS=(
    # "mysql"
    # "redis"
    # "nginx"
    # "app"
)

# 사용법 출력
show_usage() {
    cat << EOF
${CYAN}========================================
🐳 Docker Environment Extractor v1.0
========================================${NC}

${GREEN}사용법:${NC} [옵션] [컨테이너...]

${GREEN}옵션:${NC}
    -o, --output DIR     출력 디렉토리 [기본: /tmp/docker-env-extractor]
    -b, --backup         타임스탬프 포함 백업 생성
    -a, --all            실행 중인 모든 컨테이너 추출
    -v, --verbose        상세 출력 모드
    -h, --help           이 도움말 출력

${GREEN}예제:${NC}
    # 특정 컨테이너들 추출
    mysql redis nginx

    # 모든 실행 중인 컨테이너 추출
    --all

    # 백업 모드로 추출(파일명에 자동으로 타임스탬프 suffix)
    --backup mysql redis

    # 커스텀 출력 디렉토리
    -o ./backups --all

${GREEN}출력 형식:${NC}
    • 기본: .env_<container_name>
    • 백업(--backup): .env_<container_name>_<timestamp>

${CYAN}========================================${NC}
EOF
    exit 0
}

# 인자 파싱
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                OUTPUT_DIR="${2:-/tmp/docker-env-extractor}"
                shift 2
                ;;
            -b|--backup)
                CREATE_BACKUP=true
                shift
                ;;
            -a|--all)
                # 실행 중인 모든 컨테이너 가져오기
                mapfile -t CONTAINERS < <(docker ps --format "{{.Names}}")
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                # 컨테이너 이름으로 처리
                CONTAINERS+=("$1")
                shift
                ;;
        esac
    done
}

# Docker 설치 확인
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker가 설치되어 있지 않습니다${NC}"
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        echo -e "${RED}❌ Docker 데몬이 실행되고 있지 않거나 권한이 없습니다${NC}"
        echo -e "${YELLOW}💡 sudo를 사용하거나 docker 그룹에 사용자를 추가하세요${NC}"
        exit 1
    fi
}

# 컨테이너 존재 확인
check_container() {
    local container=$1
    
    if ! docker inspect "$container" &> /dev/null; then
        echo -e "${YELLOW}⚠️  컨테이너를 찾을 수 없음: $container${NC}"
        return 1
    fi
    
    # 컨테이너 상태 확인
    local state=$(docker inspect "$container" --format='{{.State.Status}}' 2>/dev/null)
    if [ "$VERBOSE" == "true" ]; then
        echo -e "  ${BLUE}상태: $state${NC}"
    fi
    
    return 0
}

# 환경변수 추출
extract_env() {
    local container=$1
    local output_file=$2
    
    echo -e "\n${CYAN}📦 컨테이너: $container${NC}"
    
    # 컨테이너 존재 확인
    if ! check_container "$container"; then
        return 1
    fi
    
    # 환경변수 추출
    local env_vars=$(docker inspect "$container" --format='{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null)
    
    if [ -z "$env_vars" ]; then
        echo -e "  ${YELLOW}⚠️  환경변수가 없습니다${NC}"
        return 1
    fi
    
    # 환경변수 개수 계산
    local env_count=$(echo "$env_vars" | grep -c '=' || true)
    echo -e "  ${GREEN}✅ 환경변수 발견: $env_count개${NC}"
    
    # 파일 헤더 작성
    {
        echo "# ========================================"
        echo "# Docker Container Environment Variables"
        echo "# Container: $container"
        echo "# Extracted: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Total: $env_count variables"
        echo "# ========================================"
        echo ""
    } > "$output_file"
    
    # 환경변수 정렬 및 저장
    echo "$env_vars" | grep '=' | sort >> "$output_file"
    
    echo -e "  ${GREEN}✅ 저장 완료: $output_file${NC}"
    
    # 상세 모드에서는 주요 변수 미리보기
    if [ "$VERBOSE" == "true" ]; then
        echo -e "  ${BLUE}📋 미리보기 (처음 5개):${NC}"
        echo "$env_vars" | grep '=' | head -5 | sed 's/^/    /'
    fi
    
    return 0
}

# 민감한 정보 마스킹 (선택적)
mask_sensitive_data() {
    local file=$1
    
    # 민감한 패턴 정의
    local sensitive_patterns=(
        "PASSWORD"
        "SECRET"
        "TOKEN"
        "KEY"
        "CREDENTIAL"
        "API_KEY"
        "PRIVATE"
    )
    
    echo -e "  ${YELLOW}🔒 민감한 정보 마스킹...${NC}"
    
    for pattern in "${sensitive_patterns[@]}"; do
        # 패턴을 포함하는 라인의 값 부분을 마스킹
        sed -i.bak -E "s/^([^=]*${pattern}[^=]*)=(.+)$/\1=***MASKED***/g" "$file"
    done
    
    # 백업 파일 제거
    rm -f "${file}.bak"
}

# 요약 보고서 생성
create_summary() {
    local output_dir=$1
    local summary_file="${output_dir}/SUMMARY.md"
    
    {
        echo "# Docker Environment Extraction Summary"
        echo ""
        echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
        echo "**Total Containers:** ${#CONTAINERS[@]}"
        echo ""
        echo "## Extracted Containers"
        echo ""
        echo "| Container | File | Variables | Size |"
        echo "|-----------|------|-----------|------|"
        
        for container in "${CONTAINERS[@]}"; do
            local filename
            if [ "$CREATE_BACKUP" == "true" ]; then
                filename="${BACKUP_PREFIX}_${container}_${TIMESTAMP}"
            else
                filename="${BACKUP_PREFIX}_${container}"
            fi
            
            local filepath="${output_dir}/${filename}"
            if [ -f "$filepath" ]; then
                local var_count=$(grep -c '=' "$filepath" 2>/dev/null || echo "0")
                local file_size=$(du -h "$filepath" | cut -f1)
                echo "| $container | $filename | $var_count | $file_size |"
            else
                echo "| $container | - | Failed | - |"
            fi
        done
        
        echo ""
        echo "## Output Directory Structure"
        echo '```'
        tree -L 1 "$output_dir" 2>/dev/null || ls -la "$output_dir"
        echo '```'
    } > "$summary_file"
    
    echo -e "\n${GREEN}📊 요약 보고서: $summary_file${NC}"
}

# 메인 함수
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}🐳 Docker Environment Extractor v1.0${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # Docker 확인
    check_docker
    
    # 컨테이너 목록 확인
    if [ ${#CONTAINERS[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  추출할 컨테이너가 지정되지 않았습니다${NC}"
        echo -e "${YELLOW}사용법: <container1> <container2> ...${NC}"
        echo -e "${YELLOW}또는: --all${NC}"
        exit 1
    fi
    
    # 출력 디렉토리 생성
    mkdir -p "$OUTPUT_DIR"
    echo -e "\n${BLUE}📁 출력 디렉토리: $OUTPUT_DIR${NC}"
    
    # 컨테이너 목록 표시
    echo -e "\n${CYAN}🎯 대상 컨테이너 (${#CONTAINERS[@]}개):${NC}"
    for container in "${CONTAINERS[@]}"; do
        echo -e "  • $container"
    done
    
    # 추출 시작
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}📤 환경변수 추출 시작${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    local success_count=0
    local fail_count=0
    
    # 각 컨테이너 처리
    for container in "${CONTAINERS[@]}"; do
        # 출력 파일명 결정
        local output_file
        if [ "$CREATE_BACKUP" == "true" ]; then
            output_file="${OUTPUT_DIR}/${BACKUP_PREFIX}_${container}_${TIMESTAMP}"
        else
            output_file="${OUTPUT_DIR}/${BACKUP_PREFIX}_${container}"
        fi
        
        # 환경변수 추출
        if extract_env "$container" "$output_file"; then
            # 민감한 정보 마스킹 옵션 (필요시 활성화)
            # mask_sensitive_data "$output_file"
            
            # 🔧 수정된 부분: 안전한 증가 방식
            success_count=$((success_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
    done
    
    # 결과 요약
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}📊 추출 완료${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "  ${GREEN}✅ 성공: $success_count개${NC}"
    if [ $fail_count -gt 0 ]; then
        echo -e "  ${RED}❌ 실패: $fail_count개${NC}"
    fi
    echo -e "  ${BLUE}📁 저장 위치: $OUTPUT_DIR${NC}"
    
    # 요약 보고서 생성
    create_summary "$OUTPUT_DIR"
    
    echo -e "\n${GREEN}✨ 작업 완료!${NC}"
}

# 스크립트 시작
parse_args "$@"
main