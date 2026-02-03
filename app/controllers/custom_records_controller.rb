class CustomRecordsController < ApplicationController
  before_action :require_organisation
  before_action :set_custom_table
  before_action :set_custom_record, only: [ :show, :edit, :update, :destroy ]
  before_action :require_unprotected_or_builder_mode, only: [ :new, :create, :edit, :update, :destroy ]

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
      missing.each { |c| @custom_record.errors.add(:"column_#{c.id}", "can't be blank") }
      render :edit, status: :unprocessable_entity
      return
    end

    success = false
    ActiveRecord::Base.transaction do
      if update_values(values)
        evaluate_computed_columns(@custom_record)
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
      missing.each { |c| @custom_record.errors.add(:"column_#{c.id}", "can't be blank") }
      render :new, status: :unprocessable_entity
      return
    end

    success = false
    ActiveRecord::Base.transaction do
      if @custom_record.save && save_values(values)
        evaluate_computed_columns(@custom_record)
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

  def search
    query = params[:q].to_s.strip
    exclude_ids = params[:exclude].to_s.split(",").map(&:to_i).reject(&:zero?)

    records = @custom_table.custom_records.includes(custom_values: :custom_column)
    records = records.where.not(id: exclude_ids) if exclude_ids.any?

    if query.present?
      records = records.joins(custom_values: :custom_column)
                       .where("custom_values.value LIKE ?", "%#{query}%")
                       .distinct
    end

    @records = records.limit(100)
    render partial: "custom_records/search_results", locals: { records: @records }
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def require_unprotected_or_builder_mode
    return unless @custom_table.protected?
    redirect_to table_path(@custom_table), alert: "This table is protected. Enable builder mode to add or edit records." unless builder_mode?
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
    @columns.reject(&:computed?).each do |column|
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

  def evaluate_computed_columns(record)
    computed = @custom_table.custom_columns.where(column_type: "computed").order(:position)
    FormulaEvaluator.evaluate_record(record, computed)
  end

  RelationshipSection = Struct.new(:relationship, :label, :is_source, :suffix, :self_referential, :symmetric, :target_table, :record_links, :display_columns, :available_records, :available_records_exclude_ids, :accepts_more, :pagy, keyword_init: true)

  def build_relationship_sections
    @custom_table.all_relationships.includes(:source_table, :target_table).flat_map do |rel|
      self_referential = rel.self_referential?

      if rel.symmetric?
        [ build_symmetric_section(rel) ]
      elsif self_referential
        [ true, false ].map { |is_source| build_section(rel, is_source, self_referential) }
      else
        [ build_section(rel, rel.source_table_id == @custom_table.id, self_referential) ]
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
    if self_referential
      exclude_ids << @custom_record.id
    end
    available_records = target_table.custom_records.where.not(id: exclude_ids).includes(custom_values: :custom_column).limit(100)

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
      self_referential: self_referential,
      symmetric: false,
      target_table: target_table,
      record_links: paginated_links,
      display_columns: display_columns,
      available_records: available_records,
      available_records_exclude_ids: exclude_ids,
      accepts_more: accepts_more,
      pagy: pagy_obj
    )
  end

  def build_symmetric_section(rel)
    target_table = rel.source_table
    suffix = "symmetric"

    all_links = rel.custom_record_links
      .where("source_record_id = :id OR target_record_id = :id", id: @custom_record.id)
      .includes(source_record: { custom_values: :custom_column }, target_record: { custom_values: :custom_column })

    linked_record_ids = all_links.map { |l| l.source_record_id == @custom_record.id ? l.target_record_id : l.source_record_id }
    display_columns = target_table.custom_columns.where(show_on_preview: true).order(:position)

    exclude_ids = linked_record_ids + [ @custom_record.id ]

    if rel.kind == "one_to_one"
      taken_ids = rel.custom_record_links.pluck(:source_record_id, :target_record_id).flatten.uniq
      exclude_ids = (exclude_ids + taken_ids).uniq
    end

    available_records = target_table.custom_records.where.not(id: exclude_ids).includes(custom_values: :custom_column).limit(100)

    accepts_more = if rel.kind == "one_to_one"
      all_links.empty?
    else
      true
    end

    search_param = :"rq_#{rel.id}_#{suffix}"
    search_query = params[search_param]
    record_links = if search_query.present?
      all_links.select { |link|
        rec = link.source_record_id == @custom_record.id ? link.target_record : link.source_record
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
      label: rel.name,
      is_source: true,
      suffix: suffix,
      self_referential: true,
      symmetric: true,
      target_table: target_table,
      record_links: paginated_links,
      display_columns: display_columns,
      available_records: available_records,
      available_records_exclude_ids: exclude_ids,
      accepts_more: accepts_more,
      pagy: pagy_obj
    )
  end
end
