class RemoveAdmissionAndTags < ActiveRecord::Migration[8.1]
  def up
    %i[route_tasks admission_routes deadlines admission_options admission_methods educational_programs faculties universities article_tags tags].each do |table|
      drop_table table
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Removed content cannot be restored"
  end
end
