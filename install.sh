#!/bin/bash
set -e

PLUGIN_NAME="openproject-measurement_charts"
MODULE_DIR_NAME="measurement_charts"
PLUGIN_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OP_DIR="${OP_DIR:-/opt/openproject}"
DEST_DIR="$OP_DIR/modules/$MODULE_DIR_NAME"

echo "========================================================="
echo " Installing OpenProject Measurement Charts Plugin        "
echo "========================================================="

if [ "$EUID" -ne 0 ]; then
  echo "[-] ERROR: Run this script with root privileges:"
  echo "    sudo bash install.sh"
  exit 1
fi

echo "[1/6] Cleaning old module and copying to $DEST_DIR..."
rm -rf "$DEST_DIR"

# Clean any previous entry from Gemfile.modules
sed -i "/$PLUGIN_NAME/d" "$OP_DIR/Gemfile.modules" 2>/dev/null || true

cp -r "$PLUGIN_SRC" "$DEST_DIR"
chown -R openproject:openproject "$DEST_DIR"

echo "[2/6] Configuring Gemfile.modules..."
if ! grep -q "$PLUGIN_NAME" "$OP_DIR/Gemfile.modules"; then
  sed -i "/group :opf_plugins do/a\\  gem '$PLUGIN_NAME', path: 'modules/$MODULE_DIR_NAME'" "$OP_DIR/Gemfile.modules"
  echo "[+] $PLUGIN_NAME entry added to group :opf_plugins."
fi

echo "[3/6] Installing Ruby dependencies (bundle install)..."
openproject run bundle config set frozen false
openproject run bundle install

echo "[4/6] Running database migrations..."
openproject run rake db:migrate

echo "[5/6] Deploying vendored Chart.js as a static asset..."
ASSET_DIR="$OP_DIR/public/assets/measurement_charts"
mkdir -p "$ASSET_DIR"
cp "$PLUGIN_SRC/app/assets/javascripts/measurement_charts/chart.umd.min.js" "$ASSET_DIR/chart.umd.min.js"
chown -R openproject:openproject "$ASSET_DIR"

echo "[6/6] Clearing cache and restarting OpenProject services..."
openproject run rake tmp:cache:clear
systemctl restart openproject-web-1 openproject-worker-1 2>/dev/null || openproject restart

echo "========================================================="
echo " [OK] Installation completed successfully!               "
echo " The 'Measurement Charts' module is now active.          "
echo " Enable it per project under Project settings > Modules, "
echo " then configure the data source and charts from the      "
echo " 'Measurement Charts' menu entry (requires the 'manage    "
echo " measurement charts' permission).                        "
echo "========================================================="
