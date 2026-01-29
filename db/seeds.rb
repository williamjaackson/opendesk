# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

admin = User.find_or_create_by!(email_address: "admin@example.com") do |user|
  user.password = "password"
  user.password_confirmation = "password"
end

5.times do |i|
  org = Organisation.find_or_create_by!(name: "Organisation #{i + 1}")
  org.users << admin unless org.users.include?(admin)
end
