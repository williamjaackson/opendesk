class CsvImport < ApplicationRecord
  STATUSES = %w[pending mapping processing completed failed].freeze
  DUPLICATE_HANDLING_OPTIONS = %w[create skip update].freeze

  belongs_to :custom_table

  has_one_attached :file

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :duplicate_handling, presence: true, inclusion: { in: DUPLICATE_HANDLING_OPTIONS }
  validates :file, presence: true, on: :create

  def pending?
    status == "pending"
  end

  def mapping?
    status == "mapping"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def progress_percentage
    return 0 if total_rows.zero?
    (processed_rows.to_f / total_rows * 100).round
  end

  def add_error(row_number, message)
    self.errors_log ||= []
    self.errors_log << { row: row_number, message: message }
    self.error_count += 1
  end
end
