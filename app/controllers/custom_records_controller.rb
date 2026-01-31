class CustomRecordsController < ApplicationController
  before_action :require_organisation
  before_action :set_custom_table

  def new
    @custom_record = @custom_table.custom_records.new
    @fields = @custom_table.custom_fields.order(:position)
  end

  def create
    @custom_record = @custom_table.custom_records.new

    if @custom_record.save
      save_values
      redirect_to custom_table_path(@custom_table)
    else
      @fields = @custom_table.custom_fields.order(:position)
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

  def save_values
    values = params[:values] || {}
    values.each do |field_id, value|
      @custom_record.custom_values.create!(custom_field_id: field_id, value: value)
    end
  end
end
