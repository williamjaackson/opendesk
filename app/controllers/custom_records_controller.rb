class CustomRecordsController < ApplicationController
  before_action :require_organisation
  before_action :set_custom_table, only: [ :new, :create ]
  before_action :set_custom_record, only: [ :show, :edit, :update, :destroy ]

  def show
    @custom_table = @custom_record.custom_table
    @fields = @custom_table.custom_fields.order(:position)
    @relationship_sections = build_relationship_sections
  end

  def edit
    @custom_table = @custom_record.custom_table
    @fields = @custom_table.custom_fields.order(:position)
  end

  def update
    @custom_table = @custom_record.custom_table
    @fields = @custom_table.custom_fields.order(:position)
    values = params[:values] || {}

    missing = @fields.where(required: true).reject { |f| values[f.id.to_s].present? }
    if missing.any?
      @custom_record.errors.add(:base, "Required fields missing: #{missing.map(&:name).join(', ')}")
      render :edit, status: :unprocessable_entity
      return
    end

    update_values(values)
    redirect_to custom_record_path(@custom_record)
  end

  def destroy
    custom_table = @custom_record.custom_table
    @custom_record.destroy
    redirect_to custom_table_path(custom_table)
  end

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

  def set_custom_record
    @custom_record = CustomRecord.joins(:custom_table)
      .where(custom_tables: { organisation_id: Current.organisation.id })
      .find(params[:id])
  end

  def save_values(values)
    values.each do |field_id, value|
      next if value.blank?
      @custom_record.custom_values.create!(custom_field_id: field_id, value: value)
    end
  end

  def update_values(values)
    @fields.each do |field|
      cv = @custom_record.custom_values.find_or_initialize_by(custom_field_id: field.id)
      value = values[field.id.to_s]

      if value.present?
        cv.update!(value: value)
      elsif cv.persisted?
        cv.destroy!
      end
    end
  end

  RelationshipSection = Struct.new(:relationship, :label, :is_source, :target_table, :record_links, :display_fields, :available_records, :accepts_more, :pagy, keyword_init: true)

  def build_relationship_sections
    @custom_table.all_relationships.includes(:source_table, :target_table).map do |rel|
      is_source = rel.source_table_id == @custom_table.id
      target_table = is_source ? rel.target_table : rel.source_table

      all_links = if is_source
        rel.custom_record_links.where(source_record: @custom_record).includes(target_record: { custom_values: :custom_field })
      else
        rel.custom_record_links.where(target_record: @custom_record).includes(source_record: { custom_values: :custom_field })
      end

      linked_record_ids = all_links.map { |l| is_source ? l.target_record_id : l.source_record_id }
      display_fields = target_table.custom_fields.order(:position).limit(3)

      taken_ids = if rel.kind == "has_one"
        is_source ? rel.custom_record_links.pluck(:target_record_id) : rel.custom_record_links.pluck(:source_record_id)
      elsif rel.kind == "has_many" && is_source
        rel.custom_record_links.pluck(:target_record_id)
      else
        []
      end

      available_records = target_table.custom_records.where.not(id: (linked_record_ids + taken_ids).uniq).includes(custom_values: :custom_field)

      accepts_more = if rel.kind == "has_one"
        all_links.empty?
      elsif rel.kind == "has_many" && !is_source
        all_links.empty?
      else
        true
      end

      search_query = params[:"rq_#{rel.id}"]
      record_links = if search_query.present?
        all_links.select { |link|
          rec = is_source ? link.target_record : link.source_record
          rec.display_name.downcase.include?(search_query.downcase)
        }
      else
        all_links.to_a
      end

      page = (params[:"rp_#{rel.id}"] || 1).to_i
      page = 1 if page < 1
      total = record_links.length
      page = [ page, (total / 25.0).ceil.clamp(1..) ].min
      pagy_obj = Pagy::Offset.new(count: total, page: page, limit: 25)
      paginated_links = record_links[pagy_obj.offset, pagy_obj.limit] || []

      RelationshipSection.new(
        relationship: rel,
        label: is_source ? rel.name : rel.inverse_name,
        is_source: is_source,
        target_table: target_table,
        record_links: paginated_links,
        display_fields: display_fields,
        available_records: available_records,
        accepts_more: accepts_more,
        pagy: pagy_obj
      )
    end
  end
end
