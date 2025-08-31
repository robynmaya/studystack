# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_31_123032) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "documents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "file_path", null: false
    t.integer "file_size_bytes", null: false
    t.string "file_type", null: false
    t.string "access_level", default: "public"
    t.decimal "price", precision: 8, scale: 2, default: "0.0"
    t.string "subject"
    t.string "school"
    t.string "document_type"
    t.string "folder_name"
    t.json "tags"
    t.integer "download_count", default: 0
    t.decimal "rating_average", precision: 3, scale: 2, default: "0.0"
    t.integer "rating_count", default: 0
    t.boolean "is_featured", default: false
    t.text "searchable_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_documents_on_created_at"
    t.index ["is_featured"], name: "index_documents_on_is_featured", where: "(is_featured = true)"
    t.index ["school"], name: "index_documents_on_school"
    t.index ["subject"], name: "index_documents_on_subject"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "user_follows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "target_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["target_id"], name: "index_user_follows_on_target_id"
    t.index ["user_id", "target_id"], name: "index_user_follows_on_user_id_and_target_id", unique: true
    t.index ["user_id"], name: "index_user_follows_on_user_id"
    t.check_constraint "user_id <> target_id", name: "user_follows_no_self_follow"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "profile_bio"
    t.string "profile_image_url"
    t.boolean "is_creator_enabled"
    t.boolean "has_public_profile"
    t.string "stripe_customer_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
  end

  add_foreign_key "documents", "users"
  add_foreign_key "user_follows", "users"
  add_foreign_key "user_follows", "users", column: "target_id"
end
