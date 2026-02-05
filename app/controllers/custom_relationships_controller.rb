class CustomRelationshipsController < ApplicationController
  before_action :require_organisation
  before_action :require_builder_mode, except: [ :export ]
  before_action :set_custom_table
  before_action :set_custom_relationship, only: [ :edit, :update, :destroy, :export, :import, :process_import ]

  def reorder
    ids = params[:ids].map(&:to_i)
    relationships = @custom_table.all_relationships.where(id: ids)
    return head :unprocessable_entity unless relationships.count == ids.size

    ActiveRecord::Base.transaction do
      ids.each_with_index do |id, index|
        relationships.find { |r| r.id == id }&.update_columns(position: index)
      end
    end

    head :no_content
  end

  def new
    @custom_relationship = @custom_table.source_relationships.new
    @available_tables = Current.organisation.custom_tables
  end

  def create
    @custom_relationship = @custom_table.source_relationships.new(custom_relationship_params)
    max = @custom_table.all_relationships.maximum(:position)
    @custom_relationship.position = max ? max + 1 : 0

    if @custom_relationship.save
      redirect_to edit_table_path(@custom_table)
    else
      @available_tables = Current.organisation.custom_tables
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @custom_relationship.update(custom_relationship_params.slice(:name, :inverse_name))
      redirect_to edit_table_path(@custom_table)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    link_count = @custom_relationship.custom_record_links.count
    if link_count > 100
      DestroyRelationshipJob.perform_later(@custom_relationship.id)
      redirect_to edit_table_path(@custom_table), notice: "Relationship is being deleted in the background."
    else
      @custom_relationship.destroy
      redirect_to edit_table_path(@custom_table)
    end
  end

  def export
    exporter = CsvExporter.new(@custom_table)
    rel_name = @custom_relationship.source_table_id == @custom_table.id ? @custom_relationship.name : @custom_relationship.inverse_name

    response.headers["Content-Type"] = "text/csv; charset=utf-8"
    response.headers["Content-Disposition"] = "attachment; filename=\"#{@custom_table.slug}-#{rel_name.parameterize}-links.csv\""

    self.response_body = exporter.generate_relationship(@custom_relationship)
  end

  def import
    @other_table = @custom_relationship.source_table_id == @custom_table.id ? @custom_relationship.target_table : @custom_relationship.source_table
  end

  def process_import
    @other_table = @custom_relationship.source_table_id == @custom_table.id ? @custom_relationship.target_table : @custom_relationship.source_table

    unless params[:file].present?
      flash.now[:alert] = "Please select a file to upload"
      return render :import, status: :unprocessable_entity
    end

    importer = RelationshipImporter.new(@custom_table, @custom_relationship, params[:file])
    @result = importer.import

    if @result[:errors].empty?
      redirect_to data_table_path(@custom_table), notice: "Successfully imported #{@result[:created]} links"
    else
      render :import_results
    end
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:table_slug])
  end

  def set_custom_relationship
    @custom_relationship = @custom_table.all_relationships.find(params[:id])
  end

  def custom_relationship_params
    params.require(:custom_relationship).permit(:name, :inverse_name, :kind, :target_table_id, :symmetric)
  end
end
