#!/usr/bin/env python

import json

rawStr = ""
try:
    with open("/etc/fluid/config/config.json", "r") as f:
        rawStr = f.readlines()
except:
    pass

if rawStr == "":
    try:
        with open("/etc/fluid/config.json", "r") as f:
            rawStr = f.readlines()
    except:
        pass

rawStr = rawStr[0]

script = """
#!/bin/sh
set -ex
# xxxxx@RDMA://0.0.0.0:8000
MNT_FROM=$mountPoint
TOKEN=$(echo $MNT_FROM | awk -F'@' '{print $1}')
RDMA=$(echo $MNT_FROM | awk -F'@' '{print $2}' | awk -F'://' '{print $2}')
RDMA="RDMA://${RDMA}"

echo $TOKEN > /opt/3fs/etc/token.txt

sed -i "s#RDMA://0.0.0.0:8000#${RDMA}#g" /opt/3fs/etc/hf3fs_fuse_main_launcher.toml

CLUSTER_ID=$clusterID
sed -i "s/^cluster_id.*/cluster_id = '${CLUSTER_ID:-default}'/" /opt/3fs/etc/hf3fs_fuse_main_launcher.toml

DEVICE_FILTER=$deviceFilter
if [[ -n "${DEVICE_FILTER}" ]]; then
  QUOTED_DEVICE_FILTER=$(echo ${DEVICE_FILTER} | sed "s/\\([^,]*\\)/'\\1'/g")
  sed -i "s|device_filter = \\[\\]|device_filter = [${QUOTED_DEVICE_FILTER}]|g" /opt/3fs/etc/hf3fs_fuse_main_launcher.toml
fi

MNT_TO=$targetPath
trap "umount ${MNT_TO}" SIGTERM
mkdir -p ${MNT_TO}
sed -i "s#/3fs/stage#${MNT_TO}#g" /opt/3fs/etc/hf3fs_fuse_main_launcher.toml

cat /opt/3fs/etc/hf3fs_fuse_main_launcher.toml

/opt/3fs/bin/hf3fs_fuse_main --launcher_cfg /opt/3fs/etc/hf3fs_fuse_main_launcher.toml
"""

obj = json.loads(rawStr)

with open("/mount-3fs.sh", "w") as f:
    f.write('mountPoint="%s"\n' % obj["mounts"][0]["mountPoint"])
    f.write('targetPath="%s"\n' % obj["targetPath"])
    f.write('clusterID="%s"\n' % obj["mounts"][0]["options"]["clusterID"])
    f.write('deviceFilter="%s"\n' % obj["mounts"][0]["options"]["deviceFilter"])
    f.write(script)
