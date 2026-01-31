class CustomTablesController < ApplicationController
  before_action :require_organisation

  def show
    @custom_table = Current.organisation.custom_tables.find(params[:id])
    @fields = @custom_table.custom_fields.order(:position)
    @records = @custom_table.custom_records.includes(custom_values: :custom_field)

    if params[:query].present?
      matching_ids = CustomValue.where(custom_field: @fields)
        .where("value LIKE ?", "%#{params[:query]}%")
        .select(:custom_record_id)
      @records = @records.where(id: matching_ids)
    end
  end

  def new
    @custom_table = Current.organisation.custom_tables.new
  end

  def edit
    @custom_table = Current.organisation.custom_tables.find(params[:id])
    @fields = @custom_table.custom_fields.order(:position)
    @fields = @fields.where("name LIKE ?", "%#{params[:query]}%") if params[:query].present?
  end

  def create
    @custom_table = Current.organisation.custom_tables.new(custom_table_params)

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
