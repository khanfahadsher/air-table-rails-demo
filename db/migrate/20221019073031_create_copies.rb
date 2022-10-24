class CreateCopies < ActiveRecord::Migration[7.1]
  def change
    create_table :copies do |t|
      t.string :key
      t.text :data
      t.timestamps
    end
  end
end
