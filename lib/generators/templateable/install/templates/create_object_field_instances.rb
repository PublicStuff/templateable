class CreateObjectFieldIntances < ActiveRecord::Migration
  def change
    create_table :object_field_instances do |t|
      t.integer :object_field_id
      t.integer :object_table_id
      t.string :object_table_type
      t.string :name
      t.text :description
      t.string :value

      t.timestamps
    end
  end
end
