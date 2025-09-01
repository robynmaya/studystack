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

ActiveRecord::Schema[8.0].define(version: 2025_09_01_022730) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "comments", force: :cascade do |t|
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.bigint "parent_comment_id"
    t.boolean "is_deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id", "created_at"], name: "index_comments_on_commentable_and_created_at"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["is_deleted"], name: "index_comments_on_is_deleted"
    t.index ["parent_comment_id"], name: "index_comments_on_parent_comment_id"
    t.index ["user_id", "created_at"], name: "index_comments_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_comments_on_user_id"
    t.check_constraint "length(TRIM(BOTH FROM content)) > 0", name: "comments_non_empty_content"
  end

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
    t.integer "duration_seconds", default: 0
    t.string "thumbnail_url"
    t.string "video_quality"
    t.boolean "has_audio", default: true
    t.string "video_codec"
    t.string "processing_status", default: "pending"
    t.index ["created_at"], name: "index_documents_on_created_at"
    t.index ["duration_seconds"], name: "index_documents_on_duration_seconds"
    t.index ["file_type", "duration_seconds"], name: "index_documents_video_duration"
    t.index ["is_featured"], name: "index_documents_on_is_featured", where: "(is_featured = true)"
    t.index ["processing_status"], name: "index_documents_on_processing_status"
    t.index ["school"], name: "index_documents_on_school"
    t.index ["subject"], name: "index_documents_on_subject"
    t.index ["user_id"], name: "index_documents_on_user_id"
    t.check_constraint "(document_type::text = ANY (ARRAY['study_guide'::character varying, 'notes'::character varying, 'practice_exam'::character varying, 'textbook'::character varying, 'summary'::character varying, 'lecture_video'::character varying, 'tutorial_video'::character varying, 'demo_video'::character varying, 'explanation_video'::character varying, 'animation'::character varying, 'presentation'::character varying, 'lab_recording'::character varying, 'solved_problems'::character varying, 'quiz_walkthrough'::character varying, 'concept_explanation'::character varying]::text[])) OR document_type IS NULL", name: "documents_valid_document_type"
    t.check_constraint "duration_seconds >= 0", name: "documents_non_negative_duration"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "subscriber_id", null: false
    t.bigint "creator_id", null: false
    t.string "stripe_subscription_id", null: false
    t.string "status", default: "incomplete", null: false
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.decimal "monthly_price", precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_subscriptions_on_creator_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["subscriber_id", "creator_id"], name: "index_subscriptions_on_subscriber_id_and_creator_id", unique: true
    t.index ["subscriber_id"], name: "index_subscriptions_on_subscriber_id"
    t.check_constraint "subscriber_id <> creator_id", name: "subscriptions_no_self_subscribe"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.bigint "seller_id", null: false
    t.bigint "document_id"
    t.string "stripe_payment_intent_id", null: false
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.decimal "platform_fee", precision: 8, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.string "transaction_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id", "created_at"], name: "index_transactions_on_buyer_id_and_created_at"
    t.index ["buyer_id"], name: "index_transactions_on_buyer_id"
    t.index ["document_id"], name: "index_transactions_on_document_id"
    t.index ["seller_id", "created_at"], name: "index_transactions_on_seller_id_and_created_at"
    t.index ["seller_id"], name: "index_transactions_on_seller_id"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["stripe_payment_intent_id"], name: "index_transactions_on_stripe_payment_intent_id", unique: true
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
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
    t.boolean "is_creator_enabled", default: false
    t.boolean "has_public_profile", default: false
    t.string "stripe_customer_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
  end

  add_foreign_key "comments", "comments", column: "parent_comment_id"
  add_foreign_key "comments", "users"
  add_foreign_key "documents", "users"
  add_foreign_key "subscriptions", "users", column: "creator_id"
  add_foreign_key "subscriptions", "users", column: "subscriber_id"
  add_foreign_key "transactions", "documents"
  add_foreign_key "transactions", "users", column: "buyer_id"
  add_foreign_key "transactions", "users", column: "seller_id"
  add_foreign_key "user_follows", "users"
  add_foreign_key "user_follows", "users", column: "target_id"
end
