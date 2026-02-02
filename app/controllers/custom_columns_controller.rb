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

  def backfill_select_options
    @options = (params[:options_text] || "").split("\n").map(&:strip).reject(&:blank?)
    render layout: false
  end

  def create
    @custom_column = @custom_table.custom_columns.new(custom_column_params)
    max = @custom_table.custom_columns.maximum(:position)
    @custom_column.position = max ? max + 1 : 0

    backfill_mode = params.dig(:custom_column, :backfill_mode)
    backfill_value = params.dig(:custom_column, :backfill_value)
    backfill_column_id = params.dig(:custom_column, :backfill_column_id)
    backfill_fallback = params.dig(:custom_column, :backfill_fallback)

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

        if backfill_fallback.present?
          test_fallback = @custom_column.custom_values.build(
            custom_record: @custom_table.custom_records.first,
            value: backfill_fallback
          )
          unless test_fallback.valid?
            @custom_column.errors.add(:backfill_fallback, test_fallback.errors[:value].first)
            raise ActiveRecord::Rollback
          end
        end

        @custom_table.custom_records.includes(:custom_values).find_each do |record|
          source_value = record.custom_values.find { |v| v.custom_column_id == source_column.id }
          value_to_use = source_value&.value.presence

          if value_to_use
            value_to_use = coerce_backfill_value(value_to_use, source_column.column_type, @custom_column.column_type)
            new_value = record.custom_values.build(custom_column: @custom_column, value: value_to_use)
            unless new_value.valid?
              if backfill_fallback.present?
                new_value.value = backfill_fallback
              else
                next
              end
            end
            new_value.save!
          elsif backfill_fallback.present?
            record.custom_values.create!(custom_column: @custom_column, value: backfill_fallback)
          end
        end
      elsif backfill_mode.present?
        @custom_column.errors.add(:backfill_mode, "is invalid")
        raise ActiveRecord::Rollback
      end

      if @custom_column.computed?
        evaluate_all_records([ @custom_column ])
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
      if @custom_column.column_type == "select"
        valid_options = @custom_column.effective_options
        @custom_column.custom_values.where.not(value: [ nil, "" ]).where.not(value: valid_options).destroy_all
      end
      if @custom_column.computed?
        evaluate_all_records([ @custom_column ])
      end
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

  DATETIME_PATTERN = /\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):[0-5]\d\z/
  DATE_PATTERN = /\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\z/
  TIME_PATTERN = /\A([01]\d|2[0-3]):[0-5]\d\z/

  def coerce_backfill_value(value, source_type, target_type)
    effective_source = source_type

    if source_type == "text"
      if value.match?(DATETIME_PATTERN)
        effective_source = "datetime"
      elsif value.match?(DATE_PATTERN)
        effective_source = "date"
      elsif value.match?(TIME_PATTERN)
        effective_source = "time"
      end
    end

    case [ effective_source, target_type ]
    when [ "datetime", "date" ]
      value.split("T").first
    when [ "datetime", "time" ]
      value.split("T").last
    when [ "date", "datetime" ]
      "#{value}T00:00"
    when [ "time", "datetime" ]
      "1970-01-01T#{value}"
    else
      value
    end
  end

  def evaluate_all_records(computed_columns)
    @custom_table.custom_records.includes(custom_values: :custom_column).find_each do |record|
      FormulaEvaluator.evaluate_record(record, computed_columns)
    end
  end

  def custom_column_params
    params.require(:custom_column).permit(:name, :column_type, :required, :show_on_preview, :options_text, :linked_column_id, :select_source, :regex_pattern, :regex_label, :formula)
  end
end
