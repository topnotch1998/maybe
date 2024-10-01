class Import::ConfigurationsController < ApplicationController
  layout "imports"

  before_action :set_import

  def show
  end

  def update
    @import.update!(import_params)
    @import.generate_rows_from_csv
    @import.reload.sync_mappings

    redirect_to import_clean_path(@import), notice: "Import configured successfully."
  end

  private
    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def import_params
      params.require(:import).permit(:date_col_label, :date_format, :name_col_label, :category_col_label, :tags_col_label, :amount_col_label, :signage_convention, :account_col_label, :notes_col_label, :entity_type_col_label)
    end
end
