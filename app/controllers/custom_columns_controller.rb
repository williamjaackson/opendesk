class CustomColumnsController < ApplicationController
  before_action :require_organisation
  before_action :require_edit_mode
  before_action :set_custom_table
  before_action :set_custom_column, only: [ :edit, :update, :destroy ]

  def reorder
    ids = params[:ids].map(&:to_i)
    columns = @custom_table.custom_columns.where(id: ids)
    return head :unprocessable_entity unless columns.count == ids.size

    ActiveRecord::Base.transaction do
      ids.each_with_index do |id, index|
        columns.find { |f| f.id == id }&.update_columns(position: index)
      end
    end

    head :no_content
  end

  def new
    @custom_column = @custom_table.custom_columns.new
    load_tables_json
    load_backfill_data
  end

  def create
    @custom_column = @custom_table.custom_columns.new(custom_column_params)
    max = @custom_table.custom_columns.maximum(:position)
    @custom_column.position = max ? max + 1 : 0

    backfill_mode = params.dig(:custom_column, :backfill_mode)
    backfill_value = params.dig(:custom_column, :backfill_value)
    backfill_column_id = params.dig(:custom_column, :backfill_column_id)

    saved = false

    ActiveRecord::Base.transaction do
      unless @custom_column.save
        raise ActiveRecord::Rollback
      end

      if backfill_mode == "fixed"
        if backfill_value.blank?
          @custom_column.errors.add(:backfill_value, "can't be blank")
          raise ActiveRecord::Rollback
        end

        test_value = @custom_column.custom_values.build(
          custom_record: @custom_table.custom_records.first,
          value: backfill_value
        )
        unless test_value.valid?
          test_value.errors[:value].each do |message|
            @custom_column.errors.add(:backfill_value, message)
          end
          raise ActiveRecord::Rollback
        end

        @custom_table.custom_records.find_each do |record|
          record.custom_values.create!(custom_column: @custom_column, value: backfill_value)
        end
      elsif backfill_mode == "column"
        if backfill_column_id.blank?
          @custom_column.errors.add(:backfill_column_id, "must be selected")
          raise ActiveRecord::Rollback
        end

        source_column = @custom_table.custom_columns.find_by(id: backfill_column_id)
        unless source_column
          @custom_column.errors.add(:backfill_column_id, "is invalid")
          raise ActiveRecord::Rollback
        end

        @custom_table.custom_records.includes(:custom_values).find_each do |record|
          source_value = record.custom_values.find { |v| v.custom_column_id == source_column.id }
          next unless source_value&.value.present?

          new_value = record.custom_values.build(custom_column: @custom_column, value: source_value.value)
          new_value.save if new_value.valid?
        end
      elsif backfill_mode.present?
        @custom_column.errors.add(:backfill_mode, "is invalid")
        raise ActiveRecord::Rollback
      end

      saved = true
    end

    if saved
      redirect_to edit_table_path(@custom_table)
    else
      load_tables_json
      load_backfill_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_tables_json
  end

  def update
    if @custom_column.update(custom_column_params.except(:column_type))
      redirect_to edit_table_path(@custom_table)
    else
      load_tables_json
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_column.destroy
    redirect_to edit_table_path(@custom_table)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:table_slug])
  end

  def set_custom_column
    @custom_column = @custom_table.custom_columns.find(params[:id])
  end

  def load_tables_json
    @tables_json = Current.organisation.custom_tables.includes(:custom_columns).map { |t|
      { id: t.id, name: t.name, columns: t.custom_columns.map { |c| { id: c.id, name: c.name } } }
    }.to_json
  end

  def load_backfill_data
    @existing_columns = @custom_table.custom_columns
    @has_records = @custom_table.custom_records.exists?
  end

  def custom_column_params
    params.require(:custom_column).permit(:name, :column_type, :required, :show_on_preview, :options_text, :linked_column_id, :select_source, :regex_pattern, :regex_label)
  end
end
