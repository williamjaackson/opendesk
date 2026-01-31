class CustomTablesController < ApplicationController
  before_action :require_organisation

  def show
    @custom_table = Current.organisation.custom_tables.find(params[:id])
    @fields = @custom_table.custom_fields.where(show_on_preview: true).order(:position)
    @records = @custom_table.custom_records.includes(custom_values: :custom_field)

    if params[:query].present?
      matching_ids = CustomValue.where(custom_field: @fields)
        .where("value LIKE ?", "%#{CustomValue.sanitize_sql_like(params[:query])}%")
        .select(:custom_record_id)
      @records = @records.where(id: matching_ids)
    end

    @pagy, @records = pagy(@records)
  end

  def new
    @custom_table = Current.organisation.custom_tables.new
  end

  def edit
    @custom_table = Current.organisation.custom_tables.find(params[:id])
    @fields = @custom_table.custom_fields.order(:position)
    @fields = @fields.where("name LIKE ?", "%#{CustomField.sanitize_sql_like(params[:query])}%") if params[:query].present?
    @pagy_fields, @fields = pagy(@fields, page_param: :fields_page)
    @relationships = @custom_table.all_relationships.includes(:source_table, :target_table)
    if params[:relationship_query].present?
      q = "%#{CustomRelationship.sanitize_sql_like(params[:relationship_query])}%"
      @relationships = @relationships.where("name LIKE ? OR inverse_name LIKE ?", q, q)
    end
    @pagy_relationships, @relationships = pagy(@relationships, page_param: :relationships_page)
  end

  def reorder
    ids = params[:ids].map(&:to_i)
    tables = Current.organisation.custom_tables.where(id: ids)
    return head :unprocessable_entity unless tables.count == ids.size

    ActiveRecord::Base.transaction do
      ids.each_with_index do |id, index|
        tables.find { |t| t.id == id }&.update_columns(position: index)
      end
    end

    head :no_content
  end

  def create
    @custom_table = Current.organisation.custom_tables.new(custom_table_params)
    @custom_table.position = Current.organisation.custom_tables.maximum(:position).to_i + 1

    if @custom_table.save
      redirect_to edit_custom_table_path(@custom_table)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @custom_table = Current.organisation.custom_tables.find(params[:id])

    if @custom_table.update(custom_table_params)
      redirect_to custom_table_path(@custom_table)
    else
      @fields = @custom_table.custom_fields.order(:position)
      @pagy_fields, @fields = pagy(@fields, page_param: :fields_page)
      @relationships = @custom_table.all_relationships.includes(:source_table, :target_table)
      @pagy_relationships, @relationships = pagy(@relationships, page_param: :relationships_page)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_table = Current.organisation.custom_tables.find(params[:id])
    @custom_table.destroy
    redirect_to dashboard_path
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def custom_table_params
    params.require(:custom_table).permit(:name)
  end
end
