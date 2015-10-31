class CreateObjectFieldAssociations < ActiveRecord::Migration
  def change
    create_table :object_field_associations do |t|
      t.integer :object_field_id
      t.integer :object_table_id
      t.string :object_table_type

      t.timestamps
    end
  end
end
