module Admin::ResourcesHelper
  def admin_record_label(record)
    case record
    when User
      "#{record.display_name} (#{record.email})"
    else
      record.try(:title) || record.try(:name) || "##{record.id}"
    end
  end

  def admin_field_options(type)
    model = type.delete_suffix("[]").constantize
    model.order(:id).map { |record| [ admin_record_label(record), record.id ] }
  end

  def admin_preview_path(record)
    url_for(controller: "/admin/#{record.model_name.route_key}", action: :preview, id: record.persisted? ? record.id : nil)
  end

  def admin_preview_cover(record)
    url = record.cover_url.to_s.strip
    url if url.match?(%r{\Ahttps?://}i)
  end
end
