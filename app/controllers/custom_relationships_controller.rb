class CustomRelationshipsController < ApplicationController
  before_action :require_organisation
  before_action :set_custom_table, only: [ :new, :create ]
  before_action :set_custom_relationship, only: [ :edit, :update, :destroy ]

  def new
    @custom_relationship = @custom_table.source_relationships.new
    @available_tables = Current.organisation.custom_tables
  end

  def create
    @custom_relationship = @custom_table.source_relationships.new(custom_relationship_params)

    if @custom_relationship.save
      redirect_to edit_custom_table_path(@custom_table)
    else
      @available_tables = Current.organisation.custom_tables
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @custom_table = @custom_relationship.source_table
  end

  def update
    @custom_table = @custom_relationship.source_table

    if @custom_relationship.update(custom_relationship_params.slice(:name, :inverse_name))
      redirect_to edit_custom_table_path(@custom_table)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    custom_table = @custom_relationship.source_table
    @custom_relationship.destroy
    redirect_to edit_custom_table_path(custom_table)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find(params[:custom_table_id])
  end

  def set_custom_relationship
    @custom_relationship = CustomRelationship.find(params[:id])
  end

  def custom_relationship_params
    params.require(:custom_relationship).permit(:name, :inverse_name, :kind, :target_table_id)
  end
end
