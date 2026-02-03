class CsvImportsController < ApplicationController
  before_action :require_organisation
  before_action :require_builder_mode
  before_action :set_custom_table
  before_action :set_csv_import, only: [ :show, :update, :destroy ]

  def new
    @csv_import = @custom_table.csv_imports.new
  end

  def create
    @csv_import = @custom_table.csv_imports.new(csv_import_params)

    if @csv_import.save
      @csv_import.update!(status: "mapping")
      redirect_to table_csv_import_path(@custom_table, @csv_import)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    if @csv_import.mapping?
      @headers = CsvImporter.new(@csv_import).parse_headers
      @preview_rows = CsvImporter.new(@csv_import).preview_rows
      @columns = @custom_table.custom_columns.where.not(column_type: "computed").order(:position)
      render :mapping
    end
  end

  def update
    if @csv_import.mapping?
      @csv_import.column_mapping = build_column_mapping

      importer = CsvImporter.new(@csv_import)
      row_count = importer.count_rows

      # Create any new columns first
      importer.create_columns_from_mapping!

      if row_count > 500
        @csv_import.update!(status: "processing")
        CsvImportJob.perform_later(@csv_import.id)
      else
        @csv_import.update!(status: "processing")
        importer.import_all
      end

      redirect_to table_csv_import_path(@custom_table, @csv_import)
    else
      redirect_to table_csv_import_path(@custom_table, @csv_import)
    end
  end

  def destroy
    @csv_import.destroy
    redirect_to edit_table_path(@custom_table)
  end

  private

  def require_organisation
    redirect_to organisations_path unless Current.organisation
  end

  def set_custom_table
    @custom_table = Current.organisation.custom_tables.find_by!(slug: params[:table_slug])
  end

  def set_csv_import
    @csv_import = @custom_table.csv_imports.find(params[:id])
  end

  def csv_import_params
    params.require(:csv_import).permit(:file)
  end

  def build_column_mapping
    mapping = {}
    return mapping unless params[:mapping]

    params[:mapping].each do |csv_header, config|
      action = config[:action]
      mapping[csv_header] = {
        "action" => action,
        "column_id" => action == "existing" ? config[:column_id] : nil,
        "type" => action == "create" ? config[:type] : nil,
        "name" => action == "create" ? config[:name] : nil
      }
    end
    mapping
  end
end
