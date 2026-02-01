class CustomFieldsController < ApplicationController
  before_action :require_organisation
  before_action :require_edit_mode
  before_action :set_custom_table
  before_action :set_custom_field, only: [ :edit, :update, :destroy ]

  def reorder
    ids = params[:ids].map(&:to_i)
    fields = @custom_table.custom_fields.where(id: ids)
    return head :unprocessable_entity unless fields.count == ids.size

    ActiveRecord::Base.transaction do
      ids.each_with_index do |id, index|
        fields.find { |f| f.id == id }&.update_columns(position: index)
      end
    end

    head :no_content
  end

  def new
    @custom_field = @custom_table.custom_fields.new
  end

  def create
    @custom_field = @custom_table.custom_fields.new(custom_field_params)
    max = @custom_table.custom_fields.maximum(:position)
    @custom_field.position = max ? max + 1 : 0

    if @custom_field.save
      redirect_to edit_table_path(@custom_table)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @custom_field.update(custom_field_params.except(:field_type))
      redirect_to edit_table_path(@custom_table)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_field.destroy
    redirect_to edit_table_path(@custom_table)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:table_slug])
  end

  def set_custom_field
    @custom_field = @custom_table.custom_fields.find(params[:id])
  end

  def custom_field_params
    params.require(:custom_field).permit(:name, :field_type, :required, :show_on_preview)
  end
end
