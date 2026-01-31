class CustomRelationshipsController < ApplicationController
  before_action :require_organisation
  before_action :set_custom_table
  before_action :set_custom_relationship, only: [ :edit, :update, :destroy ]

  def new
    @custom_relationship = @custom_table.source_relationships.new
    @available_tables = Current.organisation.custom_tables
  end

  def create
    @custom_relationship = @custom_table.source_relationships.new(custom_relationship_params)

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
    @custom_relationship.destroy
    redirect_back fallback_location: edit_table_path(@custom_table)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:table_slug])
  end

  def set_custom_relationship
    @custom_relationship = @custom_table.source_relationships.find(params[:id])
  end

  def custom_relationship_params
    params.require(:custom_relationship).permit(:name, :inverse_name, :kind, :target_table_id)
  end
end
