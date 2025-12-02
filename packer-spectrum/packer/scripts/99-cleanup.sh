#!/bin/bash
set -e

echo "Cleaning up before AMI finalization..."

# Remove temporary files
sudo rm -rf /tmp/* /var/tmp/*

# Clear package cache
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

# Clear logs (optional - comment out if you want to keep logs)
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
sudo find /var/log -type f -name "*.gz" -delete

# Clear history
sudo rm -f /root/.bash_history
sudo rm -f /home/ubuntu/.bash_history

# Clear cloud-init logs (optional)
sudo cloud-init clean --logs || true

# Zero out free space (optional - makes AMI smaller but takes longer)
# sudo dd if=/dev/zero of=/EMPTY bs=1M || true
# sudo rm -f /EMPTY

echo "Cleanup completed!"

