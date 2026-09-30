# OpenProject Measurement Charts

A project module that turns work packages of a configurable type (e.g. sensor
"measurements") into per-project chart dashboard - with every
chart's data series **freely mapped to a custom field** from a settings UI,
instead of hardcoded in code.

Native OpenProject plugin: no external service, no API
key, native permission checks, and a per-project configuration UI so any
project can point its own type and custom fields at its own
charts.

## What it does

- Adds a **"Measurement Charts"** entry to the project menu (after enabling
  the module in *Project settings > Modules*).
- The dashboard shows one or more configurable charts (line or bar), each
  with a date-range filter (7/30/90 days or custom), auto-binned into a
  maximum number of points (averaging when there are more measurements than
  that), and an optional auto-refresh - all mirroring the original app.
- **Configure data source** (`manage_measurement_charts` permission): pick
  which work package **type** holds the measurement work packages, and
  (optionally) which of its **date custom fields** the charts should be
  grouped/filtered by. Work packages without that date fall back to their
  creation date.
- **Configure charts** (same permission): create any number of charts, each
  with a title and a chart type (line/bar). Inside a chart, add any number of
  **series**, each mapped to one numeric custom field of the configured type,
  with its own:
  - label (defaults to the custom field's name)
  - color
  - unit / axis label (series sharing a unit share a Y axis, so e.g.
    Temperature/°C and Humidity/% land on distinct left/right axes the way
    the original dashboard did)
  - a fixed offset added to every raw value before charting - this replaces
    the `- 4.5` / `+ 20` sensor-calibration corrections that used to be
    hardcoded in `grafici/app/app.py` for specific fields.

Nothing about the chart layout, the source work package type, or which
custom fields feed which chart is hardcoded - it is all per-project
configuration, so the same plugin works for any project with any custom
field setup, not just the original IIPLE sensors project.

## Structure

```
app/
  controllers/
    measurement_charts_controller.rb           # dashboard (index) + JSON data endpoint
    measurement_chart_settings_controller.rb   # source config (type + date field)
    measurement_chart_widgets_controller.rb    # CRUD for charts
    measurement_chart_series_controller.rb     # CRUD for a chart's series
  models/
    measurement_chart_setting.rb    # one row per project: type + date field + bin/refresh settings
    measurement_chart_widget.rb     # one chart on the dashboard
    measurement_chart_series.rb     # one series (custom field -> chart mapping)
  views/...
  assets/javascripts/measurement_charts/chart.umd.min.js   # vendored Chart.js 4.4.4 (CSP-safe, no CDN)
lib/open_project/measurement_charts/
  engine.rb   # module/permission/menu registration
  hooks.rb    # injects the vendored Chart.js script tag on the dashboard page
  patches/project_patch.rb
db/migrate/  # measurement_chart_settings, _widgets, _series
```

## How data is loaded

Unlike the original script (which called the OpenProject REST API over HTTP
with a hardcoded API key and no permission checks), the plugin queries
`ActiveRecord` directly inside the same Rails process:

1. Work packages of the configured type, visible to the current user
   (`WorkPackage.visible`), are loaded for the project.
2. For each one, the configured date custom field's typed value is read
   (`work_package.typed_custom_value_for(field_id)`), falling back to
   `created_at` - filtered to the requested date range.
3. For every custom field referenced by any chart series, its raw numeric
   value is extracted the same way.
4. The dashboard groups these into up to `bin_count` time buckets (averaging
   within a bucket when there are more measurements than that), and each
   series' configured offset is applied client-side before drawing.

## Install

```bash
sudo bash install.sh
```

This copies the plugin into `/opt/openproject/modules/measurement_charts
`,
registers it in `Gemfile.modules`, runs `bundle install` and the database
migrations, deploys the vendored Chart.js file as a static asset, and
restarts OpenProject.

After installing:

1. Open a project's *Settings > Modules* and enable **Measurement Charts**.
2. Go to the new **Measurement Charts** menu entry > **Configure data
   source** and pick the work package type (and optionally the date custom
   field) that holds your measurements.
3. Go to **Configure charts**, add a chart, and add series to it, each
   mapped to one of that type's numeric custom fields.
4. Open **Measurement Charts** to see the dashboard.

## Permissions

- `view_measurement_charts` (public): see the dashboard.
- `manage_measurement_charts` (member): configure the data source, charts
  and series.
