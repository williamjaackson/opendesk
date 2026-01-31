class CustomRecordLinksController < ApplicationController
  before_action :require_organisation

  def create
    @link = CustomRecordLink.new(custom_record_link_params)

    if @link.save
      redirect_back fallback_location: custom_record_path(@link.source_record)
    else
      redirect_back fallback_location: custom_record_path(@link.source_record), alert: @link.errors.full_messages.join(", ")
    end
  end

  def destroy
    @link = CustomRecordLink.find(params[:id])
    record = @link.source_record
    @link.destroy
    redirect_back fallback_location: custom_record_path(record)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def custom_record_link_params
    params.require(:custom_record_link).permit(:custom_relationship_id, :source_record_id, :target_record_id)
  end
end
