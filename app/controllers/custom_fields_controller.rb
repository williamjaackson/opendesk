class CustomFieldsController < ApplicationController
  before_action :require_organisation
  before_action :set_custom_table, only: [ :new, :create ]
  before_action :set_custom_field, only: [ :edit, :update, :destroy ]

  def new
    @custom_field = @custom_table.custom_fields.new
  end

  def create
    @custom_field = @custom_table.custom_fields.new(custom_field_params)
    @custom_field.position = @custom_table.custom_fields.maximum(:position).to_i + 1

    if @custom_field.save
      redirect_to edit_custom_table_path(@custom_table)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @custom_table = @custom_field.custom_table
  end

  def update
    @custom_table = @custom_field.custom_table

    if @custom_field.update(custom_field_params.except(:field_type))
      redirect_to edit_custom_table_path(@custom_table)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    custom_table = @custom_field.custom_table
    @custom_field.destroy
    redirect_to edit_custom_table_path(custom_table)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find(params[:custom_table_id])
  end

  def set_custom_field
    @custom_field = CustomField.find(params[:id])
  end

  def custom_field_params
    params.require(:custom_field).permit(:name, :field_type, :required)
  end
end
