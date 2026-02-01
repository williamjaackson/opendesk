class CustomRecordsController < ApplicationController
  before_action :require_organisation
  before_action :set_custom_table
  before_action :set_custom_record, only: [ :show, :edit, :update, :destroy ]

  def show
    @columns = @custom_table.custom_columns.order(:position)
    @relationship_sections = build_relationship_sections
  end

  def edit
    @columns = @custom_table.custom_columns.order(:position)
  end

  def update
    @columns = @custom_table.custom_columns.order(:position)
    values = params[:values] || {}

    missing = @columns.where(required: true).reject { |c| values[c.id.to_s].present? }
    if missing.any?
      @custom_record.errors.add(:base, "Required columns missing: #{missing.map(&:name).join(', ')}")
      render :edit, status: :unprocessable_entity
      return
    end

    success = false
    ActiveRecord::Base.transaction do
      if update_values(values)
        success = true
      else
        raise ActiveRecord::Rollback
      end
    end

    if success
      redirect_to table_record_path(@custom_table, @custom_record)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_record.destroy
    redirect_to table_path(@custom_table)
  end

  def new
    @custom_record = @custom_table.custom_records.new
    @columns = @custom_table.custom_columns.order(:position)
  end

  def create
    @custom_record = @custom_table.custom_records.new
    @columns = @custom_table.custom_columns.order(:position)
    values = params[:values] || {}

    missing = @columns.where(required: true).reject { |c| values[c.id.to_s].present? }
    if missing.any?
      @custom_record.errors.add(:base, "Required columns missing: #{missing.map(&:name).join(', ')}")
      render :new, status: :unprocessable_entity
      return
    end

    success = false
    ActiveRecord::Base.transaction do
      if @custom_record.save && save_values(values)
        success = true
      else
        raise ActiveRecord::Rollback
      end
    end

    if success
      redirect_to table_path(@custom_table)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:table_slug])
  end

  def set_custom_record
    @custom_record = @custom_table.custom_records.find(params[:id])
  end

  def save_values(values)
    valid = true
    values.each do |column_id, value|
      next if value.blank?
      cv = @custom_record.custom_values.build(custom_column_id: column_id, value: value)
      unless cv.save
        column = @columns.find { |c| c.id == column_id.to_i }
        cv.errors.each do |error|
          @custom_record.errors.add(:"column_#{column.id}", error.message)
        end
        valid = false
      end
    end
    valid
  end

  def update_values(values)
    valid = true
    @columns.each do |column|
      cv = @custom_record.custom_values.find_or_initialize_by(custom_column_id: column.id)
      value = values[column.id.to_s]

      if value.present?
        cv.value = value
        unless cv.save
          cv.errors.each do |error|
            @custom_record.errors.add(:"column_#{column.id}", error.message)
          end
          valid = false
        end
      elsif cv.persisted?
        cv.destroy!
      end
    end
    valid
  end

  RelationshipSection = Struct.new(:relationship, :label, :is_source, :suffix, :target_table, :record_links, :display_columns, :available_records, :accepts_more, :pagy, keyword_init: true)

  def build_relationship_sections
    @custom_table.all_relationships.includes(:source_table, :target_table).flat_map do |rel|
      self_referential = rel.source_table_id == rel.target_table_id
      directions = self_referential ? [ true, false ] : [ rel.source_table_id == @custom_table.id ]

      directions.map do |is_source|
        build_section(rel, is_source, self_referential)
      end
    end
  end

  def build_section(rel, is_source, self_referential)
    target_table = is_source ? rel.target_table : rel.source_table
    suffix = is_source ? "source" : "target"

    all_links = if is_source
      rel.custom_record_links.where(source_record: @custom_record).includes(target_record: { custom_values: :custom_column })
    else
      rel.custom_record_links.where(target_record: @custom_record).includes(source_record: { custom_values: :custom_column })
    end

    linked_record_ids = all_links.map { |l| is_source ? l.target_record_id : l.source_record_id }
    display_columns = target_table.custom_columns.where(show_on_preview: true).order(:position)

    taken_ids = if rel.kind == "one_to_one"
      is_source ? rel.custom_record_links.pluck(:target_record_id) : rel.custom_record_links.pluck(:source_record_id)
    elsif rel.kind == "one_to_many" && is_source
      rel.custom_record_links.pluck(:target_record_id)
    elsif rel.kind == "many_to_one" && !is_source
      rel.custom_record_links.pluck(:source_record_id)
    else
      []
    end

    exclude_ids = (linked_record_ids + taken_ids).uniq
    exclude_ids << @custom_record.id if self_referential
    available_records = target_table.custom_records.where.not(id: exclude_ids).includes(custom_values: :custom_column)

    accepts_more = if rel.kind == "one_to_one"
      all_links.empty?
    elsif rel.kind == "one_to_many" && !is_source
      all_links.empty?
    elsif rel.kind == "many_to_one" && is_source
      all_links.empty?
    else
      true
    end

    search_param = :"rq_#{rel.id}_#{suffix}"
    search_query = params[search_param]
    record_links = if search_query.present?
      all_links.select { |link|
        rec = is_source ? link.target_record : link.source_record
        rec.display_name.downcase.include?(search_query.downcase)
      }
    else
      all_links.to_a
    end

    page_param = :"rp_#{rel.id}_#{suffix}"
    page = (params[page_param] || 1).to_i
    page = 1 if page < 1
    total = record_links.length
    page = [ page, (total / 25.0).ceil.clamp(1..) ].min
    pagy_obj = Pagy::Offset.new(count: total, page: page, limit: 25)
    paginated_links = record_links[pagy_obj.offset, pagy_obj.limit] || []

    RelationshipSection.new(
      relationship: rel,
      label: is_source ? rel.name : rel.inverse_name,
      is_source: is_source,
      suffix: suffix,
      target_table: target_table,
      record_links: paginated_links,
      display_columns: display_columns,
      available_records: available_records,
      accepts_more: accepts_more,
      pagy: pagy_obj
    )
  end
end
