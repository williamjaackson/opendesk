class CustomColumnsController < ApplicationController
  before_action :require_organisation
  before_action :require_edit_mode
  before_action :set_custom_table
  before_action :set_custom_column, only: [ :edit, :update, :destroy ]

  def reorder
    ids = params[:ids].map(&:to_i)
    columns = @custom_table.custom_columns.where(id: ids)
    return head :unprocessable_entity unless columns.count == ids.size

    ActiveRecord::Base.transaction do
      ids.each_with_index do |id, index|
        columns.find { |f| f.id == id }&.update_columns(position: index)
      end
    end

    head :no_content
  end

  def new
    @custom_column = @custom_table.custom_columns.new
  end

  def create
    @custom_column = @custom_table.custom_columns.new(custom_column_params)
    max = @custom_table.custom_columns.maximum(:position)
    @custom_column.position = max ? max + 1 : 0

    if @custom_column.save
      redirect_to edit_table_path(@custom_table)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @custom_column.update(custom_column_params.except(:column_type))
      redirect_to edit_table_path(@custom_table)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_column.destroy
    redirect_to edit_table_path(@custom_table)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:table_slug])
  end

  def set_custom_column
    @custom_column = @custom_table.custom_columns.find(params[:id])
  end

  def custom_column_params
    params.require(:custom_column).permit(:name, :column_type, :required, :show_on_preview)
  end
end
