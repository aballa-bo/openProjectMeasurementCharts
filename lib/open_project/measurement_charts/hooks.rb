# frozen_string_literal: true
require 'open_project/hook'
require 'digest/md5'

module OpenProject
  module MeasurementCharts
    class Hooks < ::OpenProject::Hook::ViewListener
      # Chart.js is vendored (not loaded from a CDN) because OpenProject's
      # default Content-Security-Policy only allows scripts from self, and it
      # is served with skip_pipeline so it carries no Sprockets digest. Append
      # a content hash as a query string so a redeploy busts the browser cache.
      JS_DIR = 'app/assets/javascripts/measurement_charts'

      SOURCE_FILES = {
        '/assets/measurement_charts/chart.umd.min.js' => "#{JS_DIR}/chart.umd.min.js"
      }.freeze

      def view_layouts_base_html_head(context = {})
        controller = context[:controller]
        return '' unless controller.is_a?(::MeasurementChartsController)

        vc = controller.view_context
        vc.nonced_javascript_include_tag(bust('/assets/measurement_charts/chart.umd.min.js'), skip_pipeline: true)
      end

      private

      def bust(url)
        token = asset_tokens[url]
        token ? "#{url}?v=#{token}" : url
      end

      def asset_tokens
        @asset_tokens ||= SOURCE_FILES.each_with_object({}) do |(url, rel), acc|
          path = Engine.root.join(rel)
          acc[url] = Digest::MD5.file(path).hexdigest[0, 12] if File.exist?(path)
        rescue StandardError
          next
        end
      end
    end
  end
end
