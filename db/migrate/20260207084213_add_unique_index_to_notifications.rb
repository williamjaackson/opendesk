class AddUniqueIndexToNotifications < ActiveRecord::Migration[8.1]
  def up
    remove_index :notifications, name: "index_notifications_on_notifiable"
    add_index :notifications, [ :user_id, :notifiable_type, :notifiable_id ],
              unique: true,
              name: "index_notifications_on_user_and_notifiable"
  end

  def down
    remove_index :notifications, name: "index_notifications_on_user_and_notifiable"
    add_index :notifications, [ :notifiable_type, :notifiable_id ],
              name: "index_notifications_on_notifiable"
  end
end
