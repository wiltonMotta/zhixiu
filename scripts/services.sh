#!/bin/bash
# ===== 致秀小程序 - 服务管理脚本 =====
# 使用: ./services.sh {start|stop|status|restart}

BASE_DIR=/root/private_data/sun/claudeWorkspace/zhixiu
TOOLS_DIR=/root/private_data/sun/tools
PG_BIN=$TOOLS_DIR/pgenv/bin
REDIS_BIN=$TOOLS_DIR/redis/bin
NGINX_BIN=$TOOLS_DIR/Download/nginx/sbin/nginx
PGDATA=$BASE_DIR/data/pgdata
REDIS_CONF=$BASE_DIR/data/redis/redis.conf

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

start_pg() {
    if $PG_BIN/pg_isready -h 127.0.0.1 -p 5432 -q 2>/dev/null; then
        log_info "PostgreSQL 已在运行"
    else
        log_info "启动 PostgreSQL..."
        $PG_BIN/pg_ctl -D $PGDATA -l $PGDATA/logfile start
        sleep 2
        $PG_BIN/pg_isready -h 127.0.0.1 -p 5432 -q && log_info "PostgreSQL 启动成功 ✓ (端口5432)" || log_error "PostgreSQL 启动失败 ✗"
    fi
}

stop_pg() {
    $PG_BIN/pg_isready -h 127.0.0.1 -p 5432 -q 2>/dev/null && { $PG_BIN/pg_ctl -D $PGDATA stop; log_info "PostgreSQL 已停止 ✓"; } || log_warn "PostgreSQL 未在运行"
}

status_pg() {
    $PG_BIN/pg_isready -h 127.0.0.1 -p 5432 -q 2>/dev/null && { log_info "PostgreSQL: 运行中 ✓"; } || log_warn "PostgreSQL: 未运行 ✗"
}

start_redis() {
    $REDIS_BIN/redis-cli -a zhixiu2026redis ping 2>/dev/null | grep -q PONG && log_info "Redis 已在运行" || {
        log_info "启动 Redis..."; $REDIS_BIN/redis-server $REDIS_CONF --daemonize yes; sleep 1
        $REDIS_BIN/redis-cli -a zhixiu2026redis ping 2>/dev/null | grep -q PONG && log_info "Redis 启动成功 ✓ (端口6379)" || log_error "Redis 启动失败 ✗"
    }
}

stop_redis() {
    $REDIS_BIN/redis-cli -a zhixiu2026redis ping 2>/dev/null | grep -q PONG && { $REDIS_BIN/redis-cli -a zhixiu2026redis shutdown 2>/dev/null; log_info "Redis 已停止 ✓"; } || log_warn "Redis 未在运行"
}

status_redis() {
    $REDIS_BIN/redis-cli -a zhixiu2026redis ping 2>/dev/null | grep -q PONG && { log_info "Redis: 运行中 ✓"; } || log_warn "Redis: 未运行 ✗"
}

start_nginx() {
    pgrep -f "nginx: worker" > /dev/null 2>&1 && log_info "Nginx 已在运行" || { log_info "启动 Nginx..."; $NGINX_BIN; log_info "Nginx 启动成功 ✓ (端口80)"; }
}

stop_nginx() {
    pgrep -f "nginx: master" > /dev/null 2>&1 && { $NGINX_BIN -s stop 2>/dev/null; log_info "Nginx 已停止 ✓"; } || log_warn "Nginx 未在运行"
}

status_nginx() {
    pgrep -f "nginx: worker" > /dev/null 2>&1 && log_info "Nginx: 运行中 ✓" || log_warn "Nginx: 未运行 ✗"
}

case "$1" in
    start)
        log_info "===== 启动致秀小程序服务 ====="
        start_pg; start_redis; start_nginx
        log_info "===== PostgreSQL:5432 | Redis:6379 | Nginx:80 ====="
        ;;
    stop)
        log_info "===== 停止致秀小程序服务 ====="
        stop_nginx; stop_redis; stop_pg
        ;;
    status)
        log_info "===== 致秀小程序服务状态 ====="
        status_pg; status_redis; status_nginx
        ;;
    restart)
        $0 stop; sleep 2; $0 start
        ;;
    *)
        echo "使用: $0 {start|stop|status|restart}"; exit 1
        ;;
esac
