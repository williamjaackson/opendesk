class CustomTablesController < ApplicationController
  before_action :require_organisation
  before_action :require_builder_mode, except: [ :show ]

  def show
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:slug])
    @columns = @custom_table.custom_columns.where(show_on_preview: true).order(:position)
    @records = @custom_table.custom_records.includes(custom_values: :custom_column)

    if params[:query].present?
      matching_ids = CustomValue.where(custom_column: @columns)
        .where("value LIKE ?", "%#{CustomValue.sanitize_sql_like(params[:query])}%")
        .select(:custom_record_id)
      @records = @records.where(id: matching_ids)
    end

    @pagy, @records = pagy(@records)
  end

  def new
    @custom_table = Current.organisation.custom_tables.new
    if params[:group].present?
      @custom_table.table_group = Current.organisation.table_groups.find_by(slug: params[:group])
    end
    @custom_table.table_group ||= Current.organisation.table_groups.first
  end

  def edit
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:slug])
    @columns = @custom_table.custom_columns.order(:position)
    @columns = @columns.where("name LIKE ?", "%#{CustomColumn.sanitize_sql_like(params[:query])}%") if params[:query].present?
    @pagy_columns, @columns = pagy(@columns, page_param: :columns_page)
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
    @custom_table.table_group ||= Current.organisation.table_groups.first
    @custom_table.position = Current.organisation.custom_tables.maximum(:position).to_i + 1

    if @custom_table.save
      redirect_to edit_table_path(@custom_table)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:slug])

    if @custom_table.update(custom_table_params)
      redirect_to table_path(@custom_table)
    else
      @columns = @custom_table.custom_columns.order(:position)
      @pagy_columns, @columns = pagy(@columns, page_param: :columns_page)
      @relationships = @custom_table.all_relationships.includes(:source_table, :target_table)
      @pagy_relationships, @relationships = pagy(@relationships, page_param: :relationships_page)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:slug])
    @custom_table.destroy
    redirect_to root_path
  end

  def toggle_protection
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:slug])
    @custom_table.update!(protected: !@custom_table.protected?)
    redirect_to edit_table_path(@custom_table)
  end

  def export
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:slug])
    @columns = @custom_table.custom_columns.order(:position)
    @relationships = @custom_table.all_relationships.includes(:source_table, :target_table)

    if params[:columns].present?
      column_ids = params[:columns].map(&:to_i)
      selected_columns = @custom_table.custom_columns.where(id: column_ids).order(:position)
      exporter = CsvExporter.new(@custom_table, columns: selected_columns)

      response.headers["Content-Type"] = "text/csv; charset=utf-8"
      response.headers["Content-Disposition"] = "attachment; filename=\"#{@custom_table.slug}-export.csv\""

      self.response_body = exporter.generate
    end
  end

  def template
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:slug])
    exporter = CsvExporter.new(@custom_table)

    response.headers["Content-Type"] = "text/csv; charset=utf-8"
    response.headers["Content-Disposition"] = "attachment; filename=\"#{@custom_table.slug}-template.csv\""

    self.response_body = exporter.generate_template
  end

  def data
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:slug])
    @columns = @custom_table.custom_columns.order(:position)
    @relationships = @custom_table.all_relationships.includes(:source_table, :target_table)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def custom_table_params
    permitted = params.require(:custom_table).permit(:name, :table_group_id)
    if permitted[:table_group_id].present?
      permitted[:table_group_id] = Current.organisation.table_groups.find_by(id: permitted[:table_group_id])&.id
    end
    permitted
  end
end
