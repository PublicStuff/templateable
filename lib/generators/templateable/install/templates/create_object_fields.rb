class CreateObjectFields < ActiveRecord::Migration
  def change
    create_table :object_fields do |t|
      t.string :data_type
      t.string :name
      t.text :description
      t.boolean :is_allow_null
      t.string :render_guide
      t.string :klass
      t.string :default_value

      t.timestamps
    end
  end
end
