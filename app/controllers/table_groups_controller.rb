class TableGroupsController < ApplicationController
  before_action :require_organisation

  def new
    @table_group = Current.organisation.table_groups.new
  end

  def create
    @table_group = Current.organisation.table_groups.new(table_group_params)
    @table_group.position = Current.organisation.table_groups.maximum(:position).to_i + 1

    if @table_group.save
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @table_group = Current.organisation.table_groups.find_by!(slug: params[:id])
  end

  def update
    @table_group = Current.organisation.table_groups.find_by!(slug: params[:id])

    if @table_group.update(table_group_params)
      redirect_to root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @table_group = Current.organisation.table_groups.find_by!(slug: params[:id])
    @table_group.destroy
    redirect_to root_path
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
