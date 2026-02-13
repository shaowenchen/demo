#!/bin/bash
run_monitor() {
    # env: CLICKHOUSE_DB, CLICKHOUSE_HOST, CLICKHOUSE_PASSWD, CLICKHOUSE_PORT, CLICKHOUSE_USER, DEVICE_FILTER, CLUSTER_ID
    # monitor_collector_main.toml
    sed -i "/^\[server.monitor_collector.reporter.clickhouse\]/,/^\s*$/{
    s/db = '.*/db = '${CLICKHOUSE_DB}'/;
    s/host = '.*/host = '${CLICKHOUSE_HOST}'/;
    s/passwd = '.*/passwd = '${CLICKHOUSE_PASSWD}'/;
    s/port = '.*/port = '${CLICKHOUSE_PORT}'/;
    s/user = '.*/user = '${CLICKHOUSE_USER}'/;
    }" /opt/3fs/etc/monitor_collector_main.toml
    # device_filter if set
    if [[ -n "${DEVICE_FILTER}" ]]; then
        sed -i "s|device_filter = \[\]|device_filter = [\"${DEVICE_FILTER//,/\",\"}\"]|g" /opt/3fs/etc/monitor_collector_main.toml
    fi
    # run monitor
    /opt/3fs/bin/monitor_collector_main --cfg /opt/3fs/etc/monitor_collector_main.toml
}

run_mgmtd() {
    # env: FDB_CLUSTER, MGMTD_SERVER_ADDRESSES, MGMTD_NODE_ID, DEVICE_FILTER, REMOTE_IP, CLUSTER_ID
    config_admin_cli
    echo ${FDB_CLUSTER} >/etc/foundationdb/fdb.cluster
    # mgmtd_main_launcher.toml
    sed -i "/\[fdb\]/,/^\[/{s|^clusterFile.*|clusterFile = '/etc/foundationdb/fdb.cluster'|}" /opt/3fs/etc/mgmtd_main_launcher.toml
    # mgmtd_main_app.toml
    sed -i "s/^node_id.*/node_id = ${MGMTD_NODE_ID}/" /opt/3fs/etc/mgmtd_main_app.toml
    # mgmtd_main.toml
    sed -i "s|remote_ip = .*|remote_ip = '${REMOTE_IP}'|g" /opt/3fs/etc/mgmtd_main.toml
    # device_filter
    if [[ -n "${DEVICE_FILTER}" ]]; then
        sed -i "s|device_filter = \[\]|device_filter = [\"${DEVICE_FILTER//,/\",\"}\"]|g" /opt/3fs/etc/mgmtd_main_launcher.toml
    fi
    # run mgmtd
    # if MGMTD_SERVER_ADDRESSES is prefix IPoIB, set network_type = 'RDMA' to 'IPoIB' in /opt/3fs/etc/mgmtd_main.toml
    if [[ "${MGMTD_SERVER_ADDRESSES}" == *"IPoIB"* ]]; then
        sed -i "s|network_type = 'RDMA'|network_type = 'IPoIB'|g" /opt/3fs/etc/mgmtd_main.toml
    fi
    /opt/3fs/bin/mgmtd_main --launcher_cfg /opt/3fs/etc/mgmtd_main_launcher.toml --app-cfg /opt/3fs/etc/mgmtd_main_app.toml --cfg /opt/3fs/etc/mgmtd_main.toml
}

run_meta() {
    # env: FDB_CLUSTER, MGMTD_SERVER_ADDRESSES, META_NODE_ID, DEVICE_FILTER, REMOTE_IP, CLUSTER_ID
    config_admin_cli
    # meta_main_launcher.toml
    sed -i "s|mgmtd_server_addresses = \[\]|mgmtd_server_addresses = [\"${MGMTD_SERVER_ADDRESSES//,/\",\"}\"]|g" /opt/3fs/etc/meta_main_launcher.toml
    # meta_main_app.toml
    sed -i "s/^node_id.*/node_id = ${META_NODE_ID}/" /opt/3fs/etc/meta_main_app.toml
    # meta_main.toml
    sed -i "s|mgmtd_server_addresses = \[\]|mgmtd_server_addresses = [\"${MGMTD_SERVER_ADDRESSES//,/\",\"}\"]|g" /opt/3fs/etc/meta_main.toml
    sed -i "s|remote_ip = .*|remote_ip = '${REMOTE_IP}'|g" /opt/3fs/etc/meta_main.toml
    # device_filter
    if [[ -n "${DEVICE_FILTER}" ]]; then
        sed -i "s|device_filter = \[\]|device_filter = [\"${DEVICE_FILTER//,/\",\"}\"]|g" /opt/3fs/etc/meta_main_launcher.toml
    fi
    # init meta
    /opt/3fs/bin/admin_cli -cfg /opt/3fs/etc/admin_cli.toml "set-config --type META --file /opt/3fs/etc/meta_main.toml"
    # run meta
    /opt/3fs/bin/meta_main --launcher_cfg /opt/3fs/etc/meta_main_launcher.toml --app-cfg /opt/3fs/etc/meta_main_app.toml
}

run_storage() {
    # env: FDB_CLUSTER, MGMTD_SERVER_ADDRESSES, STORAGE_NODE_ID, TARGET_PATHS, DEVICE_FILTER, REMOTE_IP, CLUSTER_ID
    config_admin_cli
    # storage_main_launcher.toml
    sed -i "s|mgmtd_server_addresses = \[\]|mgmtd_server_addresses = [\"${MGMTD_SERVER_ADDRESSES//,/\",\"}\"]|g" /opt/3fs/etc/storage_main_launcher.toml
    # storage_main_app.toml
    sed -i "s/^node_id.*/node_id = ${STORAGE_NODE_ID}/" /opt/3fs/etc/storage_main_app.toml
    # storage_main.toml
    sed -i "s|mgmtd_server_addresses = \[\]|mgmtd_server_addresses = [\"${MGMTD_SERVER_ADDRESSES//,/\",\"}\"]|g" /opt/3fs/etc/storage_main.toml
    # /opt/3fs/etc/storage_main.toml
    if [[ -n "${TARGET_PATHS}" ]]; then
        sed -i "s|^target_paths = .*|target_paths = [\"${TARGET_PATHS//,/\",\"}\"]|g" /opt/3fs/etc/storage_main.toml
    fi
    sed -i "s|remote_ip = \".*\"|remote_ip = \"${REMOTE_IP}\"|g" /opt/3fs/etc/storage_main.toml
    # device_filter
    if [[ -n "${DEVICE_FILTER}" ]]; then
        sed -i "s|device_filter = \[\]|device_filter = [\"${DEVICE_FILTER//,/\",\"}\"]|g" /opt/3fs/etc/storage_main_launcher.toml
    fi
    # init storage
    /opt/3fs/bin/admin_cli -cfg /opt/3fs/etc/admin_cli.toml "set-config --type STORAGE --file /opt/3fs/etc/storage_main.toml"
    # run storage
    /opt/3fs/bin/storage_main --launcher_cfg /opt/3fs/etc/storage_main_launcher.toml --app-cfg /opt/3fs/etc/storage_main_app.toml
}

config_cluster_id() {
    # env: CLUSTER_ID
    sed -i "s/^cluster_id.*/cluster_id = \"${CLUSTER_ID:-default}\"/" /opt/3fs/etc/*
}

config_admin_cli() {
    # env: FDB_CLUSTER, MGMTD_SERVER_ADDRESSES, DEVICE_FILTER, REMOTE_IP
    # admin_cli.toml
    echo ${FDB_CLUSTER} >/etc/foundationdb/fdb.cluster
    sed -i "s|^clusterFile.*|clusterFile = '/etc/foundationdb/fdb.cluster'|" /opt/3fs/etc/admin_cli.toml
    # remote_ip
    sed -i "s|remote_ip = \".*\"|remote_ip = \"${REMOTE_IP}\"|g" /opt/3fs/etc/mgmtd_main.toml
    # device_filter
    if [[ -n "${DEVICE_FILTER}" ]]; then
        sed -i "s|device_filter = \[\]|device_filter = [\"${DEVICE_FILTER//,/\",\"}\"]|g" /opt/3fs/etc/admin_cli.toml
    fi
    sed -i "s|mgmtd_server_addresses = \[\]|mgmtd_server_addresses = [\"${MGMTD_SERVER_ADDRESSES//,/\",\"}\"]|g" /opt/3fs/etc/admin_cli.toml
}

run_admin_cli() {
    # env: FDB_CLUSTER, MGMTD_SERVER_ADDRESSES, DEVICE_FILTER, REMOTE_IP
    config_admin_cli
    sleep infinity
}

run_fuse() {
    # env: FDB_CLUSTER, MGMTD_SERVER_ADDRESSES, TOKEN, DEVICE_FILTER, REMOTE_IP
    config_admin_cli
    mkdir -p /mnt/3fs
    # TOKEN
    echo ${TOKEN} >/opt/3fs/etc/token.txt
    # hf3fs_fuse_main_launcher.toml
    sed -i "s|mgmtd_server_addresses = \[\]|mgmtd_server_addresses = [\"${MGMTD_SERVER_ADDRESSES//,/\",\"}\"]|g" /opt/3fs/etc/hf3fs_fuse_main_launcher.toml
    sed -i "s|mountpoint = ''|mountpoint = '/mnt/3fs'|g" /opt/3fs/etc/hf3fs_fuse_main_launcher.toml
    sed -i "s|token_file = ''|token_file = '/opt/3fs/etc/token.txt'|g" /opt/3fs/etc/hf3fs_fuse_main_launcher.toml
    # hf3fs_fuse_main.toml
    sed -i "s|remote_ip = ''|remote_ip = \"${REMOTE_IP}\"|g" /opt/3fs/etc/hf3fs_fuse_main.toml
    sed -i "s|mgmtd_server_addresses = \[\]|mgmtd_server_addresses = [\"${MGMTD_SERVER_ADDRESSES//,/\",\"}\"]|g" /opt/3fs/etc/hf3fs_fuse_main.toml
    # device_filter
    if [[ -n "${DEVICE_FILTER}" ]]; then
        sed -i "s|device_filter = \[\]|device_filter = [\"${DEVICE_FILTER//,/\",\"}\"]|g" /opt/3fs/etc/hf3fs_fuse_main_launcher.toml
    fi
    # init fuse
    /opt/3fs/bin/admin_cli -cfg /opt/3fs/etc/admin_cli.toml "set-config --type FUSE --file /opt/3fs/etc/hf3fs_fuse_main.toml"
    # run fuse
    /opt/3fs/bin/hf3fs_fuse_main --launcher_cfg /opt/3fs/etc/hf3fs_fuse_main_launcher.toml
}

COMMAND=$1

case "${COMMAND}" in
monitor)
    config_cluster_id
    run_monitor
    ;;
mgmtd)
    config_cluster_id
    run_mgmtd
    ;;
meta)
    config_cluster_id
    run_meta
    ;;
storage)
    config_cluster_id
    run_storage
    ;;
admin_cli)
    config_cluster_id
    run_admin_cli
    ;;
fuse)
    config_cluster_id
    run_fuse
    ;;
*)
    echo "Usage: $0 {monitor|mgmtd|meta|storage|admin_cli}"
    exit 1
    ;;
esac
