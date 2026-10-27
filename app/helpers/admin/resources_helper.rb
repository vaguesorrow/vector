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
end
