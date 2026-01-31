class CustomTablesController < ApplicationController
  before_action :require_organisation

  def show
    @custom_table = Current.organisation.custom_tables.find(params[:id])
    @fields = @custom_table.custom_fields.order(:position)
    @records = @custom_table.custom_records.includes(custom_values: :custom_field)
  end

  def new
    @custom_table = Current.organisation.custom_tables.new
  end

  def create
    @custom_table = Current.organisation.custom_tables.new(custom_table_params)

    if @custom_table.save
      redirect_to custom_table_path(@custom_table)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def custom_table_params
    params.require(:custom_table).permit(:name)
  end
end
