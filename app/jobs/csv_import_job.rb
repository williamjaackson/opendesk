class CsvImportJob < ApplicationJob
  queue_as :default

  def perform(csv_import_id)
    csv_import = CsvImport.find(csv_import_id)
    return unless csv_import.processing?

    importer = CsvImporter.new(csv_import)
    importer.import_all
  rescue ActiveRecord::RecordNotFound
    # Import was deleted while job was queued
  rescue StandardError => e
    csv_import.update!(status: "failed", errors_log: [ { row: 0, message: e.message } ])
    raise
  end
end
