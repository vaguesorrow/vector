module Admin
  class ResourcesController < BaseController
    class_attribute :resource_model, :resource_title, :resource_fields
    before_action :load_record, only: %i[edit update destroy]
    helper_method :resource_model, :resource_title, :resource_fields, :resource_filters

    def self.manages(model, title, fields)
      self.resource_model = model
      self.resource_title = title
      self.resource_fields = fields
    end

    def index
      scope = resource_model.order(id: :desc)
      # Parent filters are limited to explicitly configured foreign keys.
      resource_fields.each do |name, _, _|
        scope = scope.where(name => params[name]) if name.to_s.end_with?("_id") && params[name].present?
      end
      @page = [ params[:page].to_i, 1 ].max
      @records = scope.offset((@page - 1) * 30).limit(31).to_a
      @more = @records.size > 30
      @records = @records.first(30)
      render "admin/resources/index"
    end

    def new
      @record ||= resource_model.new
      resource_fields.each do |name, _, _|
        @record.public_send("#{name}=", params[name]) if name.to_s.end_with?("_id") && params[name].present?
      end
      render "admin/resources/form"
    end

    def create
      @record = resource_model.new(record_params)
      persist_record(:save)
    end

    def edit
      render "admin/resources/form"
    end

    def preview
      @record = params[:id].present? ? resource_model.find(params[:id]) : resource_model.new
      @record.assign_attributes(record_params) unless request.get?
      render "admin/#{controller_name}/preview"
    end

    def update
      @record.assign_attributes(record_params)
      persist_record(:save)
    end

    def destroy
      if @record.destroy
        redirect_to url_for(action: :index), notice: "Запись удалена.", status: :see_other
      else
        redirect_to url_for(action: :index), alert: @record.errors.full_messages.join(". "), status: :see_other
      end
    rescue ActiveRecord::InvalidForeignKey
      redirect_to url_for(action: :index), alert: "Удаление запрещено: есть связанные данные.", status: :see_other
    end

    private

    def resource_filters
      names = resource_fields.map(&:first).select { |name| name.to_s.end_with?("_id") }
      params.permit(*names).to_h.symbolize_keys
    end

    def load_record
      @record = resource_model.find(params[:id])
    end

    def record_params
      permitted = resource_fields.map { |name, _, type| type.end_with?("[]") ? { name => [] } : name }
      params.require(resource_model.model_name.param_key).permit(*permitted)
    end

    def persist_record(method)
      if @record.public_send(method)
        redirect_to (@record.is_a?(Category) ? url_for(action: :index) : url_for(action: :edit, id: @record.id)), notice: "Изменения сохранены.", status: :see_other
      else
        render "admin/resources/form", status: :unprocessable_content
      end
    end
  end
end
