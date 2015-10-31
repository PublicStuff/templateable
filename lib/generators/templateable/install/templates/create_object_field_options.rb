class CreateObjectFieldOptions < ActiveRecord::Migration
  def change
    create_table :object_field_options do |t|
      t.integer :object_field_id
      t.string :name
      t.string :description
      t.string :value

      t.timestamps
    end
  end
end
