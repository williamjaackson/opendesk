class CustomRecordsController < ApplicationController
  before_action :require_organisation
  before_action :set_custom_table

  def new
    @custom_record = @custom_table.custom_records.new
    @fields = @custom_table.custom_fields.order(:position)
  end

  def create
    @custom_record = @custom_table.custom_records.new
    @fields = @custom_table.custom_fields.order(:position)
    values = params[:values] || {}

    missing = @fields.where(required: true).reject { |f| values[f.id.to_s].present? }
    if missing.any?
      @custom_record.errors.add(:base, "Required fields missing: #{missing.map(&:name).join(', ')}")
      render :new, status: :unprocessable_entity
      return
    end

    if @custom_record.save
      save_values(values)
      redirect_to custom_table_path(@custom_table)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find(params[:custom_table_id])
  end

  def save_values(values)
    values.each do |field_id, value|
      next if value.blank?
      @custom_record.custom_values.create!(custom_field_id: field_id, value: value)
    end
  end
end
