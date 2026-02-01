class TableGroupsController < ApplicationController
  before_action :require_organisation
  before_action :require_edit_mode, except: [ :index, :show ]

  def index
    @table_groups = Current.organisation.table_groups.order(:position)
    @table_groups = @table_groups.where("name LIKE ?", "%#{TableGroup.sanitize_sql_like(params[:query])}%") if params[:query].present?
    @pagy, @table_groups = pagy(@table_groups)
    @table_group = Current.organisation.table_groups.new
  end

  def show
    @table_group = Current.organisation.table_groups.find_by!(slug: params[:id])
    first_table = @table_group.custom_tables.first

    if first_table
      redirect_to table_path(first_table)
    end
  end

  def new
    @table_group = Current.organisation.table_groups.new
  end

  def create
    @table_group = Current.organisation.table_groups.new(table_group_params)
    @table_group.position = Current.organisation.table_groups.maximum(:position).to_i + 1

    if @table_group.save
      redirect_to groups_path
    else
      @table_groups = Current.organisation.table_groups.order(:position)
      @pagy, @table_groups = pagy(@table_groups)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @table_group = Current.organisation.table_groups.find_by!(slug: params[:id])
  end

  def update
    @table_group = Current.organisation.table_groups.find_by!(slug: params[:id])

    if @table_group.update(table_group_params)
      redirect_to groups_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @table_group = Current.organisation.table_groups.find_by!(slug: params[:id])

    if Current.organisation.table_groups.count <= 1
      redirect_to groups_path, alert: "Cannot delete the last group"
    elsif @table_group.custom_tables.any?
      redirect_to groups_path, alert: "Cannot delete a group that contains tables"
    else
      @table_group.destroy
      redirect_to groups_path
    end
  end

  def add_table
    @table_group = Current.organisation.table_groups.find_by!(slug: params[:id])
    table = Current.organisation.custom_tables.find(params[:table_id])
    table.update!(table_group: @table_group, position: @table_group.custom_tables.maximum(:position).to_i + 1)
    head :no_content
  end

  def reorder
    ids = params[:ids].map(&:to_i)
    groups = Current.organisation.table_groups.where(id: ids)
    return head :unprocessable_entity unless groups.count == ids.size

    ActiveRecord::Base.transaction do
      ids.each_with_index do |id, index|
        groups.find { |g| g.id == id }&.update_columns(position: index)
      end
    end

    head :no_content
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def table_group_params
    params.require(:table_group).permit(:name)
  end
end
