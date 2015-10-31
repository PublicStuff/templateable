require 'rails/generators'
require 'rails/generators/migration'

module Templateable
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)
      desc "Add the migrations for DoubleDouble"

      def self.next_migration_number(path)
        next_migration_number = current_migration_number(path) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migrations
        mig_list = ['object_field_associations', 'object_field_instances', 'object_field_options', 'object_fields']
        mig_list.each do |mig_name|
         migration_template "create_#{mig_name}.rb",
                            "db/migrate/create_#{mig_name}.rb"
        end
      end
    end
  end
end