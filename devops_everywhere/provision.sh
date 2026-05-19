#!/bin/bash

apt-get update -y
apt-get install -y apache2

cat << 'SCRIPT' > /usr/local/bin/update-dashboard.sh
#!/bin/bash

HOSTNAME=$(hostname)
UPTIME=$(uptime -p)
RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
RAM_USED=$(free -h | awk '/^Mem:/ {print $3}')
IP=$(hostname -I | awk '{print $2}')
DATETIME=$(date '+%d/%m/%Y %H:%M:%S')
DISTRO=$(lsb_release -d | awk -F'\t' '{print $2}')

cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="10">
  <title>System Dashboard</title>
  <style>
    body {
      font-family: monospace;
      background: #1e1e2e;
      color: #cdd6f4;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }
    .card {
      background: #313244;
      border-radius: 12px;
      padding: 40px;
      min-width: 400px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.4);
    }
    h1 {
      color: #cba6f7;
      margin-bottom: 30px;
      font-size: 1.4em;
      text-align: center;
      letter-spacing: 2px;
    }
    .row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #45475a;
    }
    .row:last-child { border-bottom: none; }
    .label { color: #89b4fa; }
    .value { color: #a6e3a1; }
  </style>
</head>
<body>
  <div class="card">
    <h1>⚡ System Dashboard</h1>
    <div class="row">
      <span class="label">Hostname</span>
      <span class="value">$HOSTNAME</span>
    </div>
    <div class="row">
      <span class="label">Distro</span>
      <span class="value">$DISTRO</span>
    </div>
    <div class="row">
      <span class="label">Uptime</span>
      <span class="value">$UPTIME</span>
    </div>
    <div class="row">
      <span class="label">RAM</span>
      <span class="value">$RAM_USED / $RAM_TOTAL</span>
    </div>
    <div class="row">
      <span class="label">IP</span>
      <span class="value">$IP</span>
    </div>
    <div class="row">
      <span class="label">Data e ora</span>
      <span class="value">$DATETIME</span>
    </div>
  </div>
</body>
</html>
HTML
SCRIPT

chmod +x /usr/local/bin/update-dashboard.sh
/usr/local/bin/update-dashboard.sh

echo "* * * * * root /usr/local/bin/update-dashboard.sh" > /etc/cron.d/dashboard

systemctl enable apache2
systemctl start apache2