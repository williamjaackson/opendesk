class CustomRecordLinksController < ApplicationController
  before_action :require_organisation

  def create
    @link = CustomRecordLink.new(custom_record_link_params)

    if @link.save
      redirect_back fallback_location: table_record_path(@link.source_record.custom_table, @link.source_record)
    else
      redirect_back fallback_location: table_record_path(@link.source_record.custom_table, @link.source_record), alert: @link.errors.full_messages.join(", ")
    end
  end

  def destroy
    @link = CustomRecordLink.joins(custom_relationship: :source_table)
      .where(custom_tables: { organisation_id: Current.organisation.id })
      .find(params[:id])
    record = @link.source_record
    @link.destroy
    redirect_back fallback_location: table_record_path(record.custom_table, record)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def custom_record_link_params
    params.require(:custom_record_link).permit(:custom_relationship_id, :source_record_id, :target_record_id)
  end
end
